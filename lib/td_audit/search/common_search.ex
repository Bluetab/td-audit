defmodule TdAudit.CommonSearch do
  @moduledoc false
alias TdAudit.BusinessConcept.Search

  def update_search_on_event(%{"event" => "create_quality_control", "payload" => payload, "resource_id" => _}) do
    # Field to increment in elastic bc
    field = "q_rule_count"
    update_business_concept_versions(payload, ["business_concept_id"], retrieve_script_map(field).increment_int_field)
  end

  def update_search_on_event(%{"event" => "delete_quality_control", "payload" => payload, "resource_id" => _}) do
    # Field to decrement in elastic bc
    field = "q_rule_count"
    update_business_concept_versions(payload, ["business_concept_id"], retrieve_script_map(field).decrement_int_field)
  end

  def update_search_on_event(%{"event" => "add_resource_field", "payload" => _, "resource_id" => resource_id}) do
    # Field to increment in elastic bc
    field = "link_count"
    Search.update_business_concept_by_script(%{business_concept_id: resource_id}, retrieve_script_map(field).increment_int_field)
  end

  def update_search_on_event(%{"event" => "delete_resource_field", "payload" => _, "resource_id" => resource_id}) do
    # Field to decrement in elastic bc
    field = "link_count"
    Search.update_business_concept_by_script(%{business_concept_id: resource_id}, retrieve_script_map(field).decrement_int_field)
  end

  def update_search_on_event(%{"event" => _, "payload" => _, "resource_id" => _}) do
  end

  defp update_business_concept_versions(payload, args, script) do
    payload
      |> build_args_map(args)
      |> Search.update_business_concept_by_script(script)
  end

  defp build_args_map(payload, args) do
    payload
    |> Map.take(args)
    |> Map.new(fn{k, v} -> {String.to_atom(k), v} end)
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
