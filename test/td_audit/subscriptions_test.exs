defmodule TdAudit.SubscriptionsTest do
  @moduledoc """
  Subscriptions testing module
  """
  use TdAudit.DataCase

  import TdAudit.TestOperators

  alias TdAudit.Subscriptions
  alias TdCache.AclCache
  alias TdCache.ConceptCache
  alias TdCache.DomainCache

  describe "subscriptions" do
    alias TdAudit.Subscriptions.Subscription

    test "list_subscriptions/0 returns all subscriptions" do
      subscription = insert(:subscription)
      assert Subscriptions.list_subscriptions() <|> [subscription]
    end

    test "list_subscriptions/1 returns all subscriptions filtered by subscriber_id" do
      %{id: subscriber_id} = insert(:subscriber)

      insert(:subscription)
      s1 = insert(:subscription, subscriber_id: subscriber_id)
      s2 = insert(:subscription, subscriber_id: subscriber_id)

      assert Subscriptions.list_subscriptions(subscriber_id: subscriber_id) <|> [s1, s2]
    end

    test "list_subscriptions/1 returns subscriptions filtered by events" do
      %{id: subscriber_id} = insert(:subscriber)

      insert(:subscription)

      s1 =
        insert(:subscription,
          subscriber_id: subscriber_id,
          scope: %{resource_id: 1, resource_type: "rec", events: ["event1", "event2"]}
        )

      s2 =
        insert(:subscription,
          subscriber_id: subscriber_id,
          scope: %{resource_id: 2, resource_type: "rec", events: ["event3"]}
        )

      s3 =
        insert(:subscription,
          subscriber_id: subscriber_id,
          scope: %{resource_id: 3, resource_type: "rec", events: ["event1", "event2"]}
        )

      assert Subscriptions.list_subscriptions(scope: %{events: ["event1", "event2"]}) <|> [s1, s3]
      assert Subscriptions.list_subscriptions(scope: %{events: ["event3"]}) <|> [s2]
    end

    test "get_subscription!/1 returns the subscription with given id" do
      subscription = insert(:subscription)
      assert Subscriptions.get_subscription!(subscription.id) <~> subscription
    end

    test "create_subscription/1 with valid data creates a subscription" do
      subscriber = insert(:subscriber)

      params =
        :subscription
        |> string_params_for()
        |> Map.take(["scope", "periodicity"])

      assert {:ok, %Subscription{} = _subscription} =
               Subscriptions.create_subscription(subscriber, params)
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      subscriber = insert(:subscriber)
      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_subscription(subscriber, %{})
    end

    test "update_subscription/1 with valid data updates a subscription" do
      subscription = insert(:subscription, periodicity: "daily")

      params = %{"periodicity" => "hourly"}

      assert {:ok, %Subscription{} = updated} =
               Subscriptions.update_subscription(subscription, params)

      assert updated.periodicity == "hourly"
    end

    test "update_subscription/1 with invalid data returns changeset error" do
      subscription = insert(:subscription)

      params = %{"scope" => %{"events" => []}}

      assert {:error, %Ecto.Changeset{}} = Subscriptions.update_subscription(subscription, params)
    end

    test "delete_subscription/1 deletes the subscription" do
      subscription = insert(:subscription)
      assert {:ok, %Subscription{}} = Subscriptions.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Subscriptions.get_subscription!(subscription.id) end
    end

    test "list_recipient_ids/2 gets user id for user subscription" do
      subscriber = build(:subscriber, type: "user", identifier: "42")
      subscription = insert(:subscription, subscriber: subscriber)

      assert [42] = Subscriptions.list_recipient_ids(subscription, [])
    end

    test "list_recipient_ids/2 gets user ids for domain role subscription" do
      domain_id = 42
      user_ids = [1, 2]
      AclCache.set_acl_role_users("domain", domain_id, "Domain", user_ids)

      on_exit(fn ->
        {:ok, _} = DomainCache.delete("Domain")
      end)

      subscriber = build(:subscriber, type: "role", identifier: "Domain")
      scope = build(:scope, resource_type: "domain", resource_id: Integer.to_string(domain_id))
      subscription = insert(:subscription, subscriber: subscriber, scope: scope)

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [domain_id]})
      assert %{^event_id => ^user_ids} = Subscriptions.list_recipient_ids(subscription, [event])
    end

    test "list_recipient_ids/2 gets user ids for concept role subscription" do
      domain_id = 7
      user_ids = [1, 2]
      AclCache.set_acl_role_users("domain", domain_id, "Domain", user_ids)
      ConceptCache.put(%{id: 42, name: "Concept", domain_id: domain_id})

      on_exit(fn ->
        {:ok, _} = DomainCache.delete("Domain")
        {:ok, _} = ConceptCache.delete(42)
      end)

      subscriber = build(:subscriber, type: "role", identifier: "Domain")
      scope = build(:scope, resource_type: "concept", resource_id: "42")
      subscription = insert(:subscription, subscriber: subscriber, scope: scope)

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [domain_id]})
      assert %{^event_id => ^user_ids} = Subscriptions.list_recipient_ids(subscription, [event])
    end

    test "list_recipient_ids/2 gets user ids for data_structure role subscription" do
      parent_id = System.unique_integer([:positive])
      domain_id = System.unique_integer([:positive])
      structure_id = System.unique_integer([:positive])
      user_ids = Enum.map(1..2, fn _ -> System.unique_integer([:positive]) end)
      parent = %{id: parent_id, name: "foo", updated_at: ~N[2021-01-26 14:41:14]}

      domain = %{
        id: domain_id,
        name: "bar",
        parent_ids: [parent_id],
        updated_at: ~N[2021-01-26 14:41:14]
      }

      AclCache.set_acl_role_users("domain", parent_id, "xyz", user_ids)
      DomainCache.put(parent)
      DomainCache.put(domain)

      on_exit(fn ->
        {:ok, _} = DomainCache.delete(domain_id)
        {:ok, _} = DomainCache.delete(parent_id)
        AclCache.delete_acl_roles("domain", parent_id)
      end)

      subscriber = build(:subscriber, type: "role", identifier: "xyz")

      scope =
        build(:scope,
          resource_type: "data_structure",
          resource_id: structure_id,
          domain_id: domain_id
        )

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [domain_id]})
      subscription = insert(:subscription, subscriber: subscriber, scope: scope)
      assert %{^event_id => ^user_ids} = Subscriptions.list_recipient_ids(subscription, [event])
    end

    test "list_recipient_ids/2 gets user ids for domains and role_taxonomy subscription" do
      parent_id = System.unique_integer([:positive])
      domain_id = System.unique_integer([:positive])
      user_ids = Enum.map(1..2, fn _ -> System.unique_integer([:positive]) end)

      parent = %{
        id: parent_id,
        name: "foo",
        updated_at: ~N[2021-01-26 14:41:14],
        descendent_ids: [domain_id]
      }

      domain = %{
        id: domain_id,
        name: "bar",
        parent_ids: [parent_id],
        updated_at: ~N[2021-01-26 14:41:14]
      }

      AclCache.set_acl_role_users("domain", domain_id, "xyz", user_ids)
      DomainCache.put(parent)
      DomainCache.put(domain)

      on_exit(fn ->
        {:ok, _} = DomainCache.delete(domain_id)
        {:ok, _} = DomainCache.delete(parent_id)
        AclCache.delete_acl_roles("domain", domain_id)
      end)

      subscriber = build(:subscriber, type: "taxonomy_role", identifier: "xyz")

      scope =
        build(:scope,
          resource_type: "domains",
          resource_id: parent_id
        )

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [domain_id]})
      subscription = insert(:subscription, subscriber: subscriber, scope: scope)
      assert %{^event_id => ^user_ids} = Subscriptions.list_recipient_ids(subscription, [event])
    end

    test "list_recipient_ids/2 gets user ids for the domains that events belong to and role_taxonomy subscription" do
      parent_domain_id = System.unique_integer([:positive])

      [child_1_domain_id, child_2_domain_id] =
        Enum.map(1..2, fn _ -> System.unique_integer([:positive]) end)

      members_child_1_domain = Enum.map(1..2, fn _ -> System.unique_integer([:positive]) end)
      members_child_2_domain = Enum.map(1..2, fn _ -> System.unique_integer([:positive]) end)

      parent = %{
        id: parent_domain_id,
        name: "foo",
        updated_at: ~N[2021-01-26 14:41:14],
        descendent_ids: [child_1_domain_id, child_2_domain_id]
      }

      child_1_domain = %{
        id: child_1_domain_id,
        name: "child_1_domain",
        parent_ids: [parent_domain_id],
        updated_at: ~N[2021-01-26 14:41:14]
      }

      child_2_domain = %{
        id: child_2_domain_id,
        name: "child_2_domain",
        parent_ids: [parent_domain_id],
        updated_at: ~N[2021-01-26 14:41:14]
      }

      AclCache.set_acl_role_users("domain", child_1_domain_id, "xyz", members_child_1_domain)
      AclCache.set_acl_role_users("domain", child_2_domain_id, "xyz", members_child_2_domain)
      DomainCache.put(parent)
      DomainCache.put(child_1_domain)
      DomainCache.put(child_2_domain)

      on_exit(fn ->
        {:ok, _} = DomainCache.delete(child_1_domain_id)
        {:ok, _} = DomainCache.delete(child_1_domain_id)
        {:ok, _} = DomainCache.delete(parent_domain_id)
        AclCache.delete_acl_roles("domain", child_1_domain_id)
        AclCache.delete_acl_roles("domain", child_2_domain_id)
      end)

      subscriber = build(:subscriber, type: "taxonomy_role", identifier: "xyz")

      scope =
        build(:scope,
          resource_type: "domains",
          resource_id: parent_domain_id
        )

      %{id: event_id_child_1_domain} =
        event_child_1_domain =
        insert(:event, payload: %{"domain_ids" => [child_1_domain_id, parent_domain_id]})

      %{id: event_id_child_2_domain} =
        event_child_2_domain =
        insert(:event, payload: %{"domain_ids" => [child_2_domain_id, parent_domain_id]})

      subscription = insert(:subscription, subscriber: subscriber, scope: scope)

      assert %{
               event_id_child_1_domain => members_child_1_domain,
               event_id_child_2_domain => members_child_2_domain
             } ==
               Subscriptions.list_recipient_ids(subscription, [
                 event_child_1_domain,
                 event_child_2_domain
               ])
    end
  end
end
