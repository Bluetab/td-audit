defmodule TdAudit.Subscriptions.EventsTest do
  use TdAudit.DataCase

  import TdAudit.TestOperators

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

  describe "subscription_events/1 for comment_created subscription" do
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

    test "returns new events", %{subscription: subscription} do
      events = Enum.map(1..3, fn _ -> insert(:event, event: "comment_created") end)
      assert Events.subscription_events(subscription, 1_000_000) == events
    end
  end

  describe "subscription_events/1 for rule_result_created subscription" do
    setup do
      scope =
        build(:scope,
          events: ["rule_result_created"],
          status: ["error"],
          resource_type: "concept",
          resource_id: "62"
        )

      domains_scope =
        build(:scope,
          events: ["rule_result_created"],
          status: ["fail", "warn"],
          resource_type: "domains",
          resource_id: 4
        )

      domain_scope =
        build(:scope,
          events: ["rule_result_created"],
          status: ["success"],
          resource_type: "domain",
          resource_id: 4
        )

      [
        subscription: insert(:subscription, scope: scope),
        domains_subscription: insert(:subscription, scope: domains_scope),
        domain_subscription: insert(:subscription, scope: domain_scope)
      ]
    end

    test "returns new events", %{subscription: subscription} do
      events = Enum.map(1..3, fn _ -> insert(:event, event: "rule_result_created") end)
      assert Events.subscription_events(subscription, 1_000_000) == events
    end

    test "return failed results", %{domains_subscription: subscription} do
      payload =
        string_params_for(:payload,
          event: "rule_result_created",
          status: "fail",
          domain_ids: [5, 4, 1]
        )

      event = insert(:event, event: "rule_result_created", payload: payload)
      assert Events.subscription_events(subscription, 1_000_000) == [event]
    end

    test "does not return succeeded status results", %{domains_subscription: subscription} do
      failed_payload =
        string_params_for(:payload,
          event: "rule_result_created",
          status: "fail",
          domain_ids: [5, 4, 1]
        )

      warn_payload =
        string_params_for(:payload,
          event: "rule_result_created",
          status: "warn",
          domain_ids: [5, 4, 1]
        )

      succeeded_payload =
        string_params_for(:payload,
          event: "rule_result_created",
          status: "success",
          domain_ids: [5, 4, 1]
        )

      [failed_event, _succeeded_event, warned_event] = [
        insert(:event, event: "rule_result_created", payload: failed_payload),
        insert(:event, event: "rule_result_created", payload: succeeded_payload),
        insert(:event, event: "rule_result_created", payload: warn_payload)
      ]

      assert Events.subscription_events(subscription, 1_000_000) == [failed_event, warned_event]
    end

    test "return success results of its domain", %{domain_subscription: subscription} do
      succeeded_payload_different_domain =
        string_params_for(:payload,
          event: "rule_result_created",
          status: "success",
          domain_ids: [5, 1]
        )

      failed_payload =
        string_params_for(:payload,
          event: "rule_result_created",
          status: "fail",
          domain_ids: [5, 4, 1]
        )

      warn_payload =
        string_params_for(:payload,
          event: "rule_result_created",
          status: "warn",
          domain_ids: [5, 4, 1]
        )

      succeeded_payload =
        string_params_for(:payload,
          event: "rule_result_created",
          status: "success",
          domain_ids: [4]
        )

      insert(:event, event: "rule_result_created", payload: succeeded_payload_different_domain)
      insert(:event, event: "rule_result_created", payload: failed_payload)
      event = insert(:event, event: "rule_result_created", payload: succeeded_payload)
      insert(:event, event: "rule_result_created", payload: warn_payload)
      assert Events.subscription_events(subscription, 1_000_000) == [event]
    end
  end

  describe "subscription_events/1 for rule_result_created and rule resource_type subscription" do
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

    test "returns new events", %{subscription: subscription} do
      events =
        Enum.map(1..3, fn _ ->
          insert(:event, event: "rule_result_created", resource_type: "rule")
        end)

      assert Events.subscription_events(subscription, 1_000_000) == events
    end
  end

  describe "subscription_events/1 for rule_result_created and implementation resource_type subscription" do
    setup do
      implementation_ref = 123

      scope =
        build(:scope,
          events: ["rule_result_created"],
          status: ["error"],
          resource_type: "implementation",
          resource_id: implementation_ref
        )

      %{id: last_event_id} = _old_event = insert(:event, event: "rule_result_created")

      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new events", %{subscription: subscription} do
      events =
        Enum.map(1..3, fn _ ->
          insert(:event, event: "rule_result_created", resource_type: "implementation")
        end)

      assert Events.subscription_events(subscription, 1_000_000) == events
    end
  end

  describe "subscription_events/1 for implementation status updated subscription" do
    setup do
      scope =
        build(:scope,
          events: ["implementation_status_updated"],
          status: ["published", "rejected", "submitted", "draft"],
          resource_type: "domain",
          resource_id: 19_188
        )

      [subscription: insert(:subscription, scope: scope)]
    end

    test "returns new events", %{subscription: subscription} do
      payload =
        string_params_for(:payload,
          event: "implementation_status_updated",
          status: "rejected",
          domain_ids: [19_188]
        )

      events =
        Enum.map(1..3, fn _ ->
          insert(:event, event: "implementation_status_updated", payload: payload)
        end)

      assert Events.subscription_events(subscription, 1_000_000) == events
    end
  end

  describe "subscription_events/1 for ingest_sent_for_approval subscription" do
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

    test "returns new events", %{subscription: subscription} do
      events = Enum.map(1..3, fn _ -> insert(:event, event: "ingest_sent_for_approval") end)

      assert Events.subscription_events(subscription, 1_000_000) == events
    end
  end

  describe "subscription_events/1 for ingest_sent_for_approval subscription without subdomains" do
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
      event = insert(:event, event: "ingest_sent_for_approval", payload: payload)

      assert Events.subscription_events(subscription, 1_000_000) == [event]
    end
  end

  describe "subscription_events/1 for domains" do
    setup do
      scope =
        build(:scope,
          events: ["update_concept_draft", "concept_rejection_canceled"],
          resource_type: "domains",
          resource_id: 4
        )

      payload = string_params_for(:payload, event: "update_concept_draft", domain_ids: [5, 4, 1])

      %{id: last_event_id} =
        _old_event = insert(:event, event: "update_concept_draft", payload: payload)

      [subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)]
    end

    test "returns new event ids in a child domain", %{
      subscription: subscription
    } do
      payload = string_params_for(:payload, domain_ids: [1])
      insert(:event, event: "concept_rejection_canceled", payload: payload)
      payload = string_params_for(:payload, domain_ids: [4, 1])
      insert(:event, event: "foo", payload: payload)
      payload = string_params_for(:payload, domain_ids: [4, 1])
      e1 = insert(:event, event: "concept_rejection_canceled", payload: payload)
      payload = string_params_for(:payload, domain_ids: [5, 4, 1])
      e2 = insert(:event, event: "update_concept_draft", payload: payload)

      assert Events.subscription_events(subscription, 1_000_000) ||| [e1, e2]
    end
  end

  describe "subscription_events/1 for concept related actions" do
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

    test "returns new events", %{subscription: subscription} do
      events =
        Enum.map(
          @concept_events,
          &insert(:event, event: &1, resource_id: 1, resource_type: "concept")
        )

      assert Events.subscription_events(subscription, 1_000_000) ||| events
    end
  end

  describe "subscription_events/1 for action relation_deprecated" do
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

    test "returns new events", %{subscription: subscription} do
      events =
        Enum.map(1..3, fn _ ->
          insert(:event, event: "relation_deprecated", resource_type: "concept", resource_id: 1)
        end)

      assert Events.subscription_events(subscription, 1_000_000) ||| events
    end
  end

  describe "subscription_events/1 for data_structure resource type returns both data_structure and data_structure_notes event types" do
    setup do
      data_structure_id = 42

      scope =
        build(:scope,
          events: ["structure_note_rejected", "data_structure_updated"],
          resource_type: "data_structure",
          resource_id: data_structure_id
        )

      %{id: last_event_id} =
        _old_event =
        insert(
          :event,
          event: "structure_note_rejected",
          resource_type: "data_structure_note",
          resource_id: 1,
          payload: %{"data_structure_id" => data_structure_id}
        )

      [
        data_structure_id: data_structure_id,
        subscription: insert(:subscription, scope: scope, last_event_id: last_event_id)
      ]
    end

    test "returns new events", %{data_structure_id: data_structure_id, subscription: subscription} do
      events = [
        insert(
          :event,
          event: "data_structure_updated",
          resource_type: "data_structure",
          resource_id: data_structure_id
        )
        | Enum.map(2..4, fn note_id ->
            insert(
              :event,
              event: "structure_note_rejected",
              resource_type: "data_structure_note",
              resource_id: note_id,
              payload: %{"data_structure_id" => data_structure_id}
            )
          end)
      ]

      assert Events.subscription_events(subscription, 1_000_000) ||| events
    end
  end

  describe "subscription_events/1 for arbitrary events and resource" do
    setup do
      scope =
        build(:scope,
          events: ["some_event"],
          resource_type: "some_resource_type",
          resource_id: 42
        )

      [subscription: insert(:subscription, scope: scope, last_event_id: 0)]
    end

    test "returns events", %{subscription: subscription} do
      event =
        insert(:event, event: "some_event", resource_type: "some_resource_type", resource_id: 42)

      assert Events.subscription_events(subscription, 1_000_000) ||| [event]
    end
  end

  describe "subscription_events/1 for events with subscribable fields" do
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

    test "returns events for multiple cardinality", %{s0: subscription} do
      payload = %{"subscribable_fields" => %{"foo" => ["1"]}}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_events(subscription, 1_000_000) == []

      payload = %{"subscribable_fields" => %{"foo" => "1"}}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_events(subscription, 1_000_000) == []

      payload = %{"foo" => "bar"}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_events(subscription, 1_000_000) == []

      payload = %{"subscribable_fields" => %{"foo" => ["2"]}}

      event =
        insert(:event,
          event: "some_event",
          resource_type: "concept",
          resource_id: 42,
          payload: payload
        )

      assert Events.subscription_events(subscription, 1_000_000) == [event]
    end

    test "returns events for single cardinality", %{s1: subscription} do
      payload = %{"subscribable_fields" => %{"xyz" => ["foo"]}}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_events(subscription, 1_000_000) == []

      payload = %{"subscribable_fields" => %{"xyz" => ["bar"]}}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_events(subscription, 1_000_000) == []

      payload = %{"foo" => "bar"}

      insert(:event,
        event: "some_event",
        resource_type: "concept",
        resource_id: 42,
        payload: payload
      )

      assert Events.subscription_events(subscription, 1_000_000) == []

      payload = %{"subscribable_fields" => %{"xyz" => "foo"}}

      event =
        insert(:event,
          event: "some_event",
          resource_type: "concept",
          resource_id: 42,
          payload: payload
        )

      assert Events.subscription_events(subscription, 1_000_000) == [event]
    end
  end
end
