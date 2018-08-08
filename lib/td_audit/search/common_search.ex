defmodule TdAudit.CommonSearch do
  @moduledoc false
alias TdAudit.BusinessConcept.Search
alias TdPerms.BusinessConceptCache

  def update_search_on_event(%{"event" => "create_quality_control", "payload" => payload, "resource_id" => _}) do
    # Field to increment in elastic bc
    field = "q_rule_count"
    resource_id = Map.get(payload, "business_concept_id")
    BusinessConceptCache.increment(resource_id, field)
    Search.update_business_concept_by_script(%{business_concept_id: resource_id}, retrieve_script_map(field).increment_int_field)
  end

  def update_search_on_event(%{"event" => "delete_quality_control", "payload" => payload, "resource_id" => _}) do
    # Field to decrement in elastic bc
    field = "q_rule_count"
    resource_id = Map.get(payload, "business_concept_id")
    BusinessConceptCache.decrement(resource_id, field)
    Search.update_business_concept_by_script(%{business_concept_id: resource_id}, retrieve_script_map(field).decrement_int_field)
  end

  def update_search_on_event(%{"event" => "add_resource_field", "payload" => _, "resource_id" => resource_id}) do
    # Field to increment in elastic bc
    field = "link_count"
    BusinessConceptCache.increment(resource_id, field)
    Search.update_business_concept_by_script(%{business_concept_id: resource_id}, retrieve_script_map(field).increment_int_field)
  end

  def update_search_on_event(%{"event" => "delete_resource_field", "payload" => _, "resource_id" => resource_id}) do
    # Field to decrement in elastic bc
    field = "link_count"
    BusinessConceptCache.decrement(resource_id, field)
    Search.update_business_concept_by_script(%{business_concept_id: resource_id}, retrieve_script_map(field).decrement_int_field)
  end

  def update_search_on_event(%{"event" => _, "payload" => _, "resource_id" => _}) do
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
