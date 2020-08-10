defmodule TdAudit.Subscriptions.EventsTest do
  use TdAudit.DataCase

  alias TdAudit.Subscriptions.Events

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
        |> Enum.map(fn _ -> insert(:event, event: "rule_result_created", resource_type: "rule") end)
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
      %{id: event_id} = insert(:event, event: "some_event", resource_type: "some_resource_type", resource_id: 42)
      assert Events.subscription_event_ids(subscription, 1_000_000) == [event_id]
    end
  end
end
