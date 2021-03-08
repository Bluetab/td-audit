defmodule TdAudit.Subscriptions.EventsTest do
  use TdAudit.DataCase

  alias TdAudit.Subscriptions.Events
  alias TdCache.TemplateCache

  @concept_events [
    "concept_deprecated",
    "concept_published",
    "concept_rejected",
    "concept_rejection_canceled",
    "concept_submitted",
    "delete_concept_draft",
    "new_concept_draft",
    "relation_created",
    "relation_deleted",
    "update_concept_draft"
  ]

  describe "subscription_event_ids/1 for comment_created subscription" do
    setup do
      scope =
        build(:scope,
          events: ["comment_created"],
          resource_type: "concept",
          resource_id: 1
        )

      %{id: last_event_id} = _old_event = insert(:event, event: "comment_created")
      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new event ids", %{subscription: subscription} do
      event_ids =
        1..3
        |> Enum.map(fn _ -> insert(:event, event: "comment_created") end)
        |> Enum.map(& &1.id)

      assert Events.subscription_event_ids(subscription, 1_000_000) == event_ids
    end
  end

  describe "subscription_event_ids/1 for rule_result_created subscription" do
    setup do
      scope =
        build(:scope,
          events: ["rule_result_created"],
          status: ["error"],
          resource_type: "concept",
          resource_id: "62"
        )

      %{id: last_event_id} = _old_event = insert(:event, event: "rule_result_created")

      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new event ids", %{subscription: subscription} do
      event_ids =
        1..3
        |> Enum.map(fn _ -> insert(:event, event: "rule_result_created") end)
        |> Enum.map(& &1.id)

      assert Events.subscription_event_ids(subscription, 1_000_000) == event_ids
    end
  end

  describe "subscription_event_ids/1 for rule_result_created and rule resource_type subscription" do
    setup do
      scope =
        build(:scope,
          events: ["rule_result_created"],
          status: ["error"],
          resource_type: "rule",
          resource_id: 28_280
        )

      %{id: last_event_id} = _old_event = insert(:event, event: "rule_result_created")

      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new event ids", %{subscription: subscription} do
      event_ids =
        1..3
        |> Enum.map(fn _ ->
          insert(:event, event: "rule_result_created", resource_type: "rule")
        end)
        |> Enum.map(& &1.id)

      assert Events.subscription_event_ids(subscription, 1_000_000) == event_ids
    end
  end

  describe "subscription_event_ids/1 for ingest_sent_for_approval subscription" do
    setup do
      scope =
        build(:scope,
          events: ["ingest_sent_for_approval", "ingest_submitted"],
          resource_type: "domains",
          resource_id: 4
        )

      %{id: last_event_id} = _old_event = insert(:event, event: "ingest_sent_for_approval")

      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new event ids", %{subscription: subscription} do
      event_ids =
        1..3
        |> Enum.map(fn _ -> insert(:event, event: "ingest_sent_for_approval") end)
        |> Enum.map(& &1.id)

      assert Events.subscription_event_ids(subscription, 1_000_000) == event_ids
    end
  end

  describe "subscription_event_ids/1 for ingest_sent_for_approval subscription without subdomains" do
    setup do
      scope =
        build(:scope,
          events: ["ingest_sent_for_approval", "ingest_submitted"],
          resource_type: "domain",
          resource_id: 4
        )

      payload = string_params_for(:payload, event: "ingest_sent_for_approval", domain_ids: [4, 1])

      %{id: last_event_id} =
        _old_event = insert(:event, event: "ingest_sent_for_approval", payload: payload)

      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new event ids in a domain excluding it's subdomains", %{
      subscription: subscription
    } do
      _subdomain_events =
        Enum.map(1..3, fn _ -> insert(:event, event: "ingest_sent_for_approval") end)

      payload = string_params_for(:payload, event: "ingest_sent_for_approval", domain_ids: [4, 1])
      %{id: event_id} = insert(:event, event: "ingest_sent_for_approval", payload: payload)

      assert Events.subscription_event_ids(subscription, 1_000_000) == [event_id]
    end
  end

  describe "subscription_event_ids/1 for concept related actions" do
    setup do
      scope =
        build(:scope,
          events: @concept_events,
          resource_type: "concept",
          resource_id: 1
        )

      %{id: last_event_id} = _old_event = insert(:event, event: "new_concept_draft")
      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new event ids", %{subscription: subscription} do
      event_ids =
        @concept_events
        |> Enum.map(&insert(:event, event: &1, resource_id: 1, resource_type: "concept"))
        |> Enum.map(& &1.id)

      assert Events.subscription_event_ids(subscription, 1_000_000) == event_ids
    end
  end

  describe "subscription_event_ids/1 for action relation_deprecated" do
    setup do
      scope =
        build(:scope,
          events: ["relation_deprecated"],
          resource_type: "concept",
          resource_id: 1
        )

      %{id: last_event_id} =
        _old_event =
        insert(:event, event: "relation_deprecated", resource_type: "concept", resource_id: 1)

      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new event ids", %{subscription: subscription} do
      event_ids =
        1..3
        |> Enum.map(fn _ ->
          insert(:event, event: "relation_deprecated", resource_type: "concept", resource_id: 1)
        end)
        |> Enum.map(& &1.id)

      assert Events.subscription_event_ids(subscription, 1_000_000) == event_ids
    end
  end

  describe "subscription_event_ids/1 for arbitrary events and resource" do
    setup do
      scope =
        build(:scope,
          events: ["some_event"],
          resource_type: "some_resource_type",
          resource_id: 42
        )

      [subscription: insert(:subscription, scope: scope, last_event_id: 0)]
    end

    test "returns event ids", %{subscription: subscription} do
      %{id: event_id} =
        insert(:event, event: "some_event", resource_type: "some_resource_type", resource_id: 42)

      assert Events.subscription_event_ids(subscription, 1_000_000) == [event_id]
    end
  end

  describe "subscription_event_ids/1 for events with subscribable fields" do
    setup do
      content = [
        %{
          "name" => "group",
          "fields" => [
            %{
              name: "foo",
              type: "string",
              cardinality: "*",
              values: %{
                "fixed_tuple" => [
                  %{"name" => "foo", "value" => "2"},
                  %{"name" => "bar", "value" => "1"}
                ]
              },
              subscribable: true
            },
            %{
              name: "xyz",
              type: "string",
              cardinality: "?",
              values: %{"fixed" => ["foo", "bar"]},
              subscribable: true
            }
          ]
        }
      ]

      template_id = System.unique_integer([:positive])

      TemplateCache.put(%{
        id: template_id,
        name: "foo",
        label: "label",
        scope: "test",
        content: content,
        updated_at: DateTime.utc_now()
      })

      scope0 =
        build(:scope,
          events: ["some_event"],
          resource_type: "concept",
          resource_id: 42,
          filters: %{
            content: %{"name" => "foo", "value" => "2"},
            template: %{"id" => template_id}
          }
        )

      scope1 =
        build(:scope,
          events: ["some_event"],
          resource_type: "concept",
          resource_id: 42,
          filters: %{
            content: %{"name" => "xyz", "value" => "foo"},
            template: %{"id" => template_id}
          }
        )

      [
        s0: insert(:subscription, scope: scope0, last_event_id: 0),
        s1: insert(:subscription, scope: scope1, last_event_id: 0)
      ]
    end

    test "returns event ids for multiple cardinality", %{s0: subscription} do
      payload = %{"subscribable_fields" => %{"foo" => ["1"]}}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_event_ids(subscription, 1_000_000) == []

      payload = %{"subscribable_fields" => %{"foo" => "1"}}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_event_ids(subscription, 1_000_000) == []

      payload = %{"foo" => "bar"}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_event_ids(subscription, 1_000_000) == []

      payload = %{"subscribable_fields" => %{"foo" => ["2"]}}

      %{id: event_id} =
        insert(:event,
          event: "some_event",
          resource_type: "concept",
          resource_id: 42,
          payload: payload
        )

      assert Events.subscription_event_ids(subscription, 1_000_000) == [event_id]
    end

    test "returns event ids for single cardinality", %{s1: subscription} do
      payload = %{"subscribable_fields" => %{"xyz" => ["foo"]}}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_event_ids(subscription, 1_000_000) == []

      payload = %{"subscribable_fields" => %{"xyz" => ["bar"]}}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_event_ids(subscription, 1_000_000) == []

      payload = %{"foo" => "bar"}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_event_ids(subscription, 1_000_000) == []

      payload = %{"subscribable_fields" => %{"xyz" => "foo"}}

      %{id: event_id} =
        insert(:event,
          event: "some_event",
          resource_type: "concept",
          resource_id: 42,
          payload: payload
        )

      assert Events.subscription_event_ids(subscription, 1_000_000) == [event_id]
    end
  end
end
