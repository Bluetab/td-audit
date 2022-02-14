defmodule TdAudit.SubscriptionsTest do
  @moduledoc """
  Subscriptions testing module
  """
  use TdAudit.DataCase

  import TdAudit.TestOperators

  alias TdAudit.Subscriptions
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

  describe "list_recipient_ids/2" do
    test "gets user id for user subscription" do
      subscriber = build(:subscriber, type: "user", identifier: "42")
      subscription = insert(:subscription, subscriber: subscriber)

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [1]})

      assert %{^event_id => [42]} = Subscriptions.list_recipient_ids(subscription, [event])
    end

    test "gets user ids for domain role subscription" do
      users = Enum.map(1..2, fn _ -> CacheHelpers.put_user() end)
      %{id: domain_id} = CacheHelpers.put_domain()
      CacheHelpers.put_acl_role_users(domain_id, "some_role", users)

      subscriber = build(:subscriber, type: "role", identifier: "some_role")
      scope = build(:scope, resource_type: "domain", resource_id: Integer.to_string(domain_id))
      subscription = insert(:subscription, subscriber: subscriber, scope: scope)

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [domain_id]})
      assert %{^event_id => user_ids} = Subscriptions.list_recipient_ids(subscription, [event])
      assert_lists_equal(user_ids, users, &(&1 == &2.id))
    end

    test "gets user ids for concept role subscription" do
      users = Enum.map(1..3, fn _ -> CacheHelpers.put_user() end)

      %{id: domain_id} = CacheHelpers.put_domain()
      %{id: concept_id} = CacheHelpers.put_concept(domain_id: domain_id)
      CacheHelpers.put_acl_role_users(domain_id, "role_123", users)

      subscription =
        insert(:subscription,
          subscriber: build(:subscriber, type: "role", identifier: "role_123"),
          scope: build(:scope, resource_type: "concept", resource_id: "#{concept_id}")
        )

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [domain_id]})
      assert %{^event_id => user_ids} = Subscriptions.list_recipient_ids(subscription, [event])
      assert_lists_equal(user_ids, users, &(&1 == &2.id))
    end

    test "gets user ids for data_structure role subscription" do
      structure_id = System.unique_integer([:positive])

      users = Enum.map(1..2, fn _ -> CacheHelpers.put_user() end)

      %{id: parent_id} = CacheHelpers.put_domain()
      %{id: domain_id} = CacheHelpers.put_domain(parent_id: parent_id)

      CacheHelpers.put_acl_role_users(parent_id, "xyz", users)

      subscriber = build(:subscriber, type: "role", identifier: "xyz")

      scope =
        build(:scope,
          resource_type: "data_structure",
          resource_id: structure_id,
          domain_id: domain_id
        )

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [domain_id]})
      subscription = insert(:subscription, subscriber: subscriber, scope: scope)
      assert %{^event_id => user_ids} = Subscriptions.list_recipient_ids(subscription, [event])
      assert_lists_equal(user_ids, users, &(&1 == &2.id))
    end

    test "gets user ids for domains and role_taxonomy subscription" do
      %{id: parent_id} = CacheHelpers.put_domain()
      %{id: domain_id} = CacheHelpers.put_domain(parent_id: parent_id)
      users = Enum.map(1..2, fn _ -> CacheHelpers.put_user() end)
      CacheHelpers.put_acl_role_users(domain_id, "xyz", users)

      subscription =
        insert(:subscription,
          subscriber: build(:subscriber, type: "taxonomy_role", identifier: "xyz"),
          scope: build(:scope, resource_type: "domains", resource_id: parent_id)
        )

      %{id: event_id} = event = insert(:event, payload: %{"domain_ids" => [domain_id]})
      assert %{^event_id => user_ids} = Subscriptions.list_recipient_ids(subscription, [event])
      assert_lists_equal(user_ids, users, &(&1 == &2.id))
    end

    test "gets user ids for the domains that events belong to and role_taxonomy subscription" do
      users_1 = Enum.map(1..2, fn _ -> CacheHelpers.put_user() end)
      users_2 = Enum.map(1..2, fn _ -> CacheHelpers.put_user() end)

      %{id: parent_domain_id} = CacheHelpers.put_domain()
      %{id: child_1_domain_id} = CacheHelpers.put_domain(parent_id: parent_domain_id)
      %{id: child_2_domain_id} = CacheHelpers.put_domain(parent_id: parent_domain_id)
      CacheHelpers.put_acl_role_users(child_1_domain_id, "xyz", users_1)
      CacheHelpers.put_acl_role_users(child_2_domain_id, "xyz", users_2)

      subscription =
        insert(:subscription,
          subscriber: build(:subscriber, type: "taxonomy_role", identifier: "xyz"),
          scope: build(:scope, resource_type: "domains", resource_id: parent_domain_id)
        )

      %{id: event_id_child_1_domain} =
        event_child_1_domain =
        insert(:event, payload: %{"domain_ids" => [child_1_domain_id, parent_domain_id]})

      %{id: event_id_child_2_domain} =
        event_child_2_domain =
        insert(:event, payload: %{"domain_ids" => [child_2_domain_id, parent_domain_id]})

      assert %{
               ^event_id_child_1_domain => user_ids_1,
               ^event_id_child_2_domain => user_ids_2
             } =
               Subscriptions.list_recipient_ids(subscription, [
                 event_child_1_domain,
                 event_child_2_domain
               ])

      assert_lists_equal(user_ids_1, users_1, &(&1 == &2.id))
      assert_lists_equal(user_ids_2, users_2, &(&1 == &2.id))
    end
  end
end
