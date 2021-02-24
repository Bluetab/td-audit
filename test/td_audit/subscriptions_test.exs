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

    test "list_recipient_ids/1 gets user id for user subscription" do
      subscriber = build(:subscriber, type: "user", identifier: "42")
      subscription = insert(:subscription, subscriber: subscriber)

      assert [42] = Subscriptions.list_recipient_ids(subscription)
    end

    test "list_recipient_ids/1 gets user ids for domain role subscription" do
      AclCache.set_acl_role_users("domain", 42, "Domain", [1, 2])

      on_exit(fn ->
        {:ok, _} = DomainCache.delete("Domain")
      end)

      subscriber = build(:subscriber, type: "role", identifier: "Domain")
      scope = build(:scope, resource_type: "domain", resource_id: "42")
      subscription = insert(:subscription, subscriber: subscriber, scope: scope)

      assert [1, 2] = Subscriptions.list_recipient_ids(subscription)
    end

    test "list_recipient_ids/1 gets user ids for concept role subscription" do
      AclCache.set_acl_role_users("domain", 7, "Domain", [1, 2])
      ConceptCache.put(%{id: 42, name: "Concept", domain_id: 7})

      on_exit(fn ->
        {:ok, _} = DomainCache.delete("Domain")
        {:ok, _} = ConceptCache.delete(42)
      end)

      subscriber = build(:subscriber, type: "role", identifier: "Domain")
      scope = build(:scope, resource_type: "concept", resource_id: "42")
      subscription = insert(:subscription, subscriber: subscriber, scope: scope)

      assert [1, 2] = Subscriptions.list_recipient_ids(subscription)
    end
  end
end
