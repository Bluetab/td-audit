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
    assert Subscriptions.list_subscriptions() ||| [subscription]
  end

  test "list_subscriptions/1 returns all subscriptions filtered by subscriber_id" do
    %{id: subscriber_id} = insert(:subscriber)

    insert(:subscription)
    s1 = insert(:subscription, subscriber_id: subscriber_id)
    s2 = insert(:subscription, subscriber_id: subscriber_id)

    assert Subscriptions.list_subscriptions(subscriber_id: subscriber_id) ||| [s1, s2]
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

    assert Subscriptions.list_subscriptions(scope: %{events: ["event1", "event2"]}) ||| [s1, s3]
    assert Subscriptions.list_subscriptions(scope: %{events: ["event3"]}) ||| [s2]
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

  test "create_subscription/1 with quality_control_version_status_updated event creates a subscription" do
    subscriber = insert(:subscriber)

    params = %{
      "periodicity" => "daily",
      "scope" => %{
        "events" => ["quality_control_version_status_updated"],
        "resource_type" => "quality_control",
        "resource_id" => 1,
        "status" => [
          "draft",
          "pending_approval",
          "rejected",
          "published",
          "versioned",
          "deprecated"
        ]
      }
    }

    assert {:ok, %Subscription{} = _subscription} =
             Subscriptions.create_subscription(subscriber, params)
  end

  test "create_subscription/1 with invalid quality_control_version_status_updated event returns error changeset" do
    subscriber = insert(:subscriber)

    params = %{
      "periodicity" => "daily",
      "scope" => %{
        "events" => ["quality_control_version_status_updated"],
        "resource_type" => "quality_control",
        "resource_id" => 1,
        "status" => ["invalid"]
      }
    }

    assert {:error, %Ecto.Changeset{changes: %{scope: %{errors: errors}}}} =
             Subscriptions.create_subscription(subscriber, params)

    assert errors == [
             status:
               {"is invalid",
                [
                  validation: :inclusion,
                  enum: [
                    "draft",
                    "pending_approval",
                    "rejected",
                    "published",
                    "versioned",
                    "deprecated"
                  ]
                ]}
           ]
  end

  test "create_subscription/1 with score_status_updated event creates a subscription" do
    subscriber = insert(:subscriber)

    params = %{
      "periodicity" => "daily",
      "scope" => %{
        "events" => ["score_status_updated"],
        "resource_type" => "quality_control",
        "resource_id" => 1,
        "status" => [
          "failed",
          "succeeded"
        ]
      }
    }

    assert {:ok, %Subscription{} = _subscription} =
             Subscriptions.create_subscription(subscriber, params)
  end

  test "create_subscription/1 with invalid score_status_updated event returns error changeset" do
    subscriber = insert(:subscriber)

    params = %{
      "periodicity" => "daily",
      "scope" => %{
        "events" => ["score_status_updated"],
        "status" => ["invalid"],
        "resource_type" => "quality_control",
        "resource_id" => 1
      }
    }

    assert {:error, %Ecto.Changeset{changes: %{scope: %{errors: errors}}}} =
             Subscriptions.create_subscription(subscriber, params)

    assert errors == [
             status:
               {"is invalid",
                [
                  validation: :inclusion,
                  enum: [
                    "failed",
                    "succeeded"
                  ]
                ]}
           ]
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
      CacheHelpers.put_acl_role_users("domain", domain_id, "some_role", users)

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
      CacheHelpers.put_acl_role_users("domain", domain_id, "role_123", users)

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

      CacheHelpers.put_acl_role_users("domain", parent_id, "xyz", users)

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
      CacheHelpers.put_acl_role_users("domain", domain_id, "xyz", users)

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
      CacheHelpers.put_acl_role_users("domain", child_1_domain_id, "xyz", users_1)
      CacheHelpers.put_acl_role_users("domain", child_2_domain_id, "xyz", users_2)

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

    test "grant_created event sets only granted user as recipient" do
      %{id: granted_user_id} = CacheHelpers.put_user()

      %{id: user_1_id} = user_1 = CacheHelpers.put_user()

      user_2 = CacheHelpers.put_user()

      %{id: domain_id} = CacheHelpers.put_domain()

      CacheHelpers.put_acl_role_users("domain", domain_id, "xyz", [user_1, user_2])

      %{id: event_id} =
        event =
        insert(:event,
          event: "grant_created",
          payload: %{"user_id" => granted_user_id, "domain_ids" => [domain_id]}
        )

      role_subscription =
        insert(:subscription,
          subscriber: build(:subscriber, type: "role", identifier: "xyz"),
          scope: build(:scope, events: ["grant_created"], resource_id: 2, resource_type: "domain")
        )

      assert %{^event_id => [^granted_user_id]} =
               Subscriptions.list_recipient_ids(role_subscription, [event])

      taxonomy_role_subscription =
        insert(:subscription,
          subscriber: build(:subscriber, type: "taxonomy_role", identifier: "xyz"),
          scope:
            build(:scope, events: ["grant_created"], resource_id: 2, resource_type: "domains")
        )

      assert %{^event_id => [^granted_user_id]} =
               Subscriptions.list_recipient_ids(taxonomy_role_subscription, [event])

      user_subscription =
        insert(:subscription,
          subscriber: build(:subscriber, type: "user", identifier: Integer.to_string(user_1_id)),
          scope: build(:scope, events: ["grant_created"], resource_id: 2, resource_type: "domain")
        )

      assert %{^event_id => [^granted_user_id]} =
               Subscriptions.list_recipient_ids(user_subscription, [event])
    end

    test "grant_request_group_creation adds users with subscription rol in structure" do
      domain_in_subscription_id = System.unique_integer([:positive])
      structure_in_subscription_id = System.unique_integer([:positive])

      domain_id = System.unique_integer([:positive])
      structure_id = System.unique_integer([:positive])

      role = "Notify Me"

      %{id: user_role_in_domain_and_structure_subscription_id} = CacheHelpers.put_user()
      %{id: user_role_in_domain_subscription_id} = CacheHelpers.put_user()
      %{id: user_role_in_structure_subscription_id} = CacheHelpers.put_user()
      %{id: user_role_in_domain_and_structure_id} = CacheHelpers.put_user()
      %{id: user_role_in_domain_id} = CacheHelpers.put_user()
      %{id: user_role_in_structure_id} = CacheHelpers.put_user()
      %{id: user_id} = CacheHelpers.put_user()

      CacheHelpers.put_acl_role_users("domain", domain_in_subscription_id, role, [
        user_role_in_domain_and_structure_subscription_id,
        user_role_in_domain_subscription_id
      ])

      CacheHelpers.put_acl_role_users("structure", structure_in_subscription_id, role, [
        user_role_in_domain_and_structure_subscription_id,
        user_role_in_structure_subscription_id
      ])

      CacheHelpers.put_acl_role_users("domain", domain_id, role, [
        user_role_in_domain_and_structure_id,
        user_role_in_domain_id
      ])

      CacheHelpers.put_acl_role_users("structure", structure_id, role, [
        user_role_in_domain_and_structure_id,
        user_role_in_structure_id
      ])

      event = "grant_request_group_creation"

      payload = %{
        "requests" => [
          %{"data_structure" => %{"id" => structure_in_subscription_id}},
          %{"data_structure" => %{"id" => structure_id}}
        ],
        "domain_ids" => [
          [domain_in_subscription_id, System.unique_integer([:positive])],
          [domain_id]
        ]
      }

      %{id: event_id} = inserted_event = insert(:event, event: event, payload: payload)

      subscriber = insert(:subscriber, type: "role", identifier: role)

      scope = %{events: [event], resource_id: domain_in_subscription_id, resource_type: "domain"}

      inserted_subscription =
        insert(:subscription, periodicity: "minutely", subscriber: subscriber, scope: scope)

      recipient_ids =
        Subscriptions.list_recipient_ids(
          inserted_subscription,
          [inserted_event]
        )
        |> Map.get(event_id)

      assert Enum.member?(recipient_ids, user_role_in_domain_and_structure_subscription_id)
      assert Enum.member?(recipient_ids, user_role_in_domain_subscription_id)
      assert Enum.member?(recipient_ids, user_role_in_structure_subscription_id)
      refute Enum.member?(recipient_ids, user_role_in_domain_and_structure_id)
      refute Enum.member?(recipient_ids, user_role_in_domain_id)
      refute Enum.member?(recipient_ids, user_role_in_structure_id)
      refute Enum.member?(recipient_ids, user_id)
    end

    test "grant_request_group_creation will not add users for not corresponding events" do
      %{id: user_id_1} = CacheHelpers.put_user()
      %{id: user_id_2} = CacheHelpers.put_user()

      structure_id_1 = System.unique_integer([:positive])
      structure_id_2 = System.unique_integer([:positive])

      domain_id = System.unique_integer([:positive])
      role = "role"

      CacheHelpers.put_acl_role_users("structure", structure_id_1, role, [user_id_1])
      CacheHelpers.put_acl_role_users("structure", structure_id_2, role, [user_id_2])

      subscriber = insert(:subscriber, type: "role", identifier: role)

      subscription =
        insert(:subscription,
          subscriber: subscriber,
          scope: %{
            events: ["grant_request_group_creation"],
            resource_id: domain_id,
            resource_type: "domain"
          }
        )

      %{id: event1_id} =
        event1 =
        insert(:event,
          event: "grant_request_group_creation",
          payload: %{
            "requests" => [
              %{"data_structure" => %{"id" => structure_id_1}}
            ],
            "domain_ids" => [[domain_id]]
          }
        )

      %{id: event2_id} =
        event2 =
        insert(:event,
          event: "grant_request_group_creation",
          payload: %{
            "requests" => [
              %{"data_structure" => %{"id" => structure_id_2}}
            ],
            "domain_ids" => [[domain_id]]
          }
        )

      assert %{
               ^event1_id => [^user_id_1],
               ^event2_id => [^user_id_2]
             } = Subscriptions.list_recipient_ids(subscription, [event1, event2])
    end

    test "grant_request_group_creation events considers child domains" do
      %{id: parent_id} = CacheHelpers.put_domain()
      %{id: domain_id} = CacheHelpers.put_domain(parent_id: parent_id)

      %{id: user_id} = CacheHelpers.put_user()
      structure_id = System.unique_integer([:positive])
      role = "role"

      CacheHelpers.put_acl_role_users("structure", structure_id, role, [user_id])

      subscriber = insert(:subscriber, type: "taxonomy_role", identifier: role)

      subscription =
        insert(:subscription,
          subscriber: subscriber,
          scope: %{
            events: ["grant_request_group_creation"],
            resource_id: parent_id,
            resource_type: "domains"
          }
        )

      %{id: event_id} =
        event =
        insert(:event,
          event: "grant_request_group_creation",
          payload: %{
            "requests" => [%{"data_structure" => %{"id" => structure_id}}],
            "domain_ids" => [[domain_id]]
          }
        )

      assert %{^event_id => [^user_id]} = Subscriptions.list_recipient_ids(subscription, [event])
    end
  end
end
