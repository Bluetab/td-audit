defmodule TdAudit.SearchEventProcessor do
  require Logger
  @moduledoc false
  alias TdAudit.BusinessConcept.Search

  @bc_cache Application.get_env(:td_audit, :bc_cache)

  def process_event(%{
    "event" => "create_rule",
    "payload" => %{
      "business_concept_id" => resource_id
    }
  }) do
    @bc_cache.increment(resource_id, "rule_count")

    Search.update_business_concept_by_script(
      %{business_concept_id: resource_id},
      retrieve_script_map("rule_count").increment_int_field
    )
  end
  def process_event(%{
    "event" => "delete_rule",
    "payload" => %{
      "business_concept_id" => resource_id
    }
  }) do
    @bc_cache.decrement(resource_id, "rule_count")

    Search.update_business_concept_by_script(
      %{business_concept_id: resource_id},
      retrieve_script_map("rule_count").decrement_int_field
    )
  end
  def process_event(%{
    "event" => "add_relation",
    "resource_id" => resource_id,
    "payload" => %{"target_type" => "data_field"}
  }) do
    @bc_cache.increment(resource_id, "link_count")

    Search.update_business_concept_by_script(
      %{business_concept_id: resource_id},
      retrieve_script_map("link_count").increment_int_field
    )
  end
  def process_event(%{
    "event" => "delete_relation",
    "resource_id" => resource_id,
    "payload" => %{"target_type" => "data_field"}
  }) do
    @bc_cache.decrement(resource_id, "link_count")

    Search.update_business_concept_by_script(
      %{business_concept_id: resource_id},
      retrieve_script_map("link_count").decrement_int_field
    )
  end
  def process_event(%{"event" => event, "resource_id" => resource_id}) do
    Logger.info(
      "SearchEventProcessor not implemented for event #{event} and resource_id #{resource_id}"
    )
  end

  defp retrieve_script_map(field) do
    %{
      decrement_int_field: """
      if (ctx._source.#{field} > 0) {
        ctx._source.#{field}--;
      }
      """,
      increment_int_field: "ctx._source.#{field}++"
    }
  end
end
