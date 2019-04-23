defmodule TdAudit.SearchEventProcessorTest do
  @moduledoc """
  This module will test the effects of events on search
  """
  use ExUnit.Case
  use TdAudit.DataCase

  alias TdAudit.SearchEventProcessor
  alias TdPerms.MockBusinessConceptCache

  setup_all do
    start_supervised(MockBusinessConceptCache)
    :ok
  end

  test "process_event/1 for create_rule event returns correct query" do
    event = %{
      "event" => "create_rule",
      "payload" => %{"business_concept_id" => "8"}
    }
    expected_query = %{
      query: %{term: %{business_concept_id: "8"}},
      script: %{lang: "painless", source: "ctx._source.rule_count++"}
    }

    assert SearchEventProcessor.process_event(event) == expected_query
  end

  test "process_event/1 for create_rule event increments cache rule_count" do
    MockBusinessConceptCache.clean_cache()

    event = %{
      "event" => "create_rule",
      "payload" => %{"business_concept_id" => "8"}
    }

    assert MockBusinessConceptCache.get_field_values("8", ["rule_count"]) == %{}
    SearchEventProcessor.process_event(event)
    assert MockBusinessConceptCache.get_field_values("8", ["rule_count"]) == %{"rule_count" => 1}
  end

  test "process_event/1 for delete_rule event returns correct query" do
    event = %{
      "event" => "delete_rule",
      "payload" => %{"business_concept_id" => "8"}
    }
    expected_query = %{
      query: %{term: %{business_concept_id: "8"}},
      script: %{
        lang: "painless",
        source: "if (ctx._source.rule_count > 0) {\n  ctx._source.rule_count--;\n}\n"
      }
    }

    assert SearchEventProcessor.process_event(event) == expected_query
  end

  test "process_event/1 for delete_rule event decrement cache rule_count" do
    MockBusinessConceptCache.clean_cache()

    event = %{
      "event" => "delete_rule",
      "payload" => %{"business_concept_id" => "8"}
    }

    MockBusinessConceptCache.increment("8", "rule_count")
    MockBusinessConceptCache.increment("8", "rule_count")
    assert MockBusinessConceptCache.get_field_values("8", ["rule_count"]) == %{"rule_count" => 2}
    SearchEventProcessor.process_event(event)
    assert MockBusinessConceptCache.get_field_values("8", ["rule_count"]) == %{"rule_count" => 1}
  end

  test "process_event/1 for add_relation event returns correct query" do
    event = %{
      "event" => "add_relation",
      "resource_id" => "8",
      "payload" => %{"target_type" => "data_field"}
    }
    expected_query = %{
      query: %{term: %{business_concept_id: "8"}},
      script: %{lang: "painless", source: "ctx._source.link_count++"}
    }

    assert SearchEventProcessor.process_event(event) == expected_query
  end

  test "process_event/1 for add_relation event increments cache link_count" do
    MockBusinessConceptCache.clean_cache()

    event = %{
      "event" => "add_relation",
      "resource_id" => "8",
      "payload" => %{"target_type" => "data_field"}
    }

    assert MockBusinessConceptCache.get_field_values("8", ["link_count"]) == %{}
    SearchEventProcessor.process_event(event)
    assert MockBusinessConceptCache.get_field_values("8", ["link_count"]) == %{"link_count" => 1}
  end

  test "process_event/1 for add_relation will do nothing for business_concept target_type" do
    MockBusinessConceptCache.clean_cache()

    event = %{
      "event" => "add_relation",
      "resource_id" => "8",
      "payload" => %{"target_type" => "business_concept"}
    }

    assert MockBusinessConceptCache.get_field_values("8", ["link_count"]) == %{}
    assert SearchEventProcessor.process_event(event) == :ok
    assert MockBusinessConceptCache.get_field_values("8", ["link_count"]) == %{}
  end

  test "process_event/1 for delete_relation event returns correct query" do
    event = %{
      "event" => "delete_relation",
      "resource_id" => "8",
      "payload" => %{"target_type" => "data_field"}
    }
    expected_query = %{
      query: %{term: %{business_concept_id: "8"}},
      script: %{
        lang: "painless",
        source: "if (ctx._source.link_count > 0) {\n  ctx._source.link_count--;\n}\n"
      }
    }

    assert SearchEventProcessor.process_event(event) == expected_query
  end

  test "process_event/1 for delete_relation event decrement cache link_count" do
    MockBusinessConceptCache.clean_cache()

    event = %{
      "event" => "delete_relation",
      "resource_id" => "8",
      "payload" => %{"target_type" => "data_field"}
    }

    MockBusinessConceptCache.increment("8", "link_count")
    MockBusinessConceptCache.increment("8", "link_count")
    assert MockBusinessConceptCache.get_field_values("8", ["link_count"]) == %{"link_count" => 2}
    SearchEventProcessor.process_event(event)
    assert MockBusinessConceptCache.get_field_values("8", ["link_count"]) == %{"link_count" => 1}
  end

  test "process_event/1 for delete_relation event will do nothing for business_concept target_type" do
    MockBusinessConceptCache.clean_cache()

    event = %{
      "event" => "delete_relation",
      "resource_id" => "8",
      "payload" => %{"target_type" => "business_concept"}
    }

    MockBusinessConceptCache.increment("8", "link_count")
    MockBusinessConceptCache.increment("8", "link_count")
    assert MockBusinessConceptCache.get_field_values("8", ["link_count"]) == %{"link_count" => 2}
    assert SearchEventProcessor.process_event(event) == :ok
    assert MockBusinessConceptCache.get_field_values("8", ["link_count"]) == %{"link_count" => 2}
  end
end
