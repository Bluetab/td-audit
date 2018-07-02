defmodule TdAudit.BusinessConcept.Search do
  @moduledoc """
    Helper module to construct business concept search queries.
  """
  alias TdAudit.Search.Aggregations

  @search_service Application.get_env(:td_audit, :elasticsearch)[:search_service]

  def update_business_concept_by_script(params, command) do
    query = create_query(params)
    script = create_script(command, "painless")

    payload = %{
      query: query,
      script: script
    }

    @search_service.udapte_by_query("business_concept", payload)
  end

  def create_filters(%{"filters" => filters}) do
    filters
    |> Map.to_list()
    |> Enum.map(&to_terms_query/1)
  end

  def create_filters(_), do: []

  defp to_terms_query({filter, values}) do
    field =
      Aggregations.bc_aggregation_terms()
      |> Map.get(filter)
      |> get_filter_field

    %{terms: %{field => values}}
  end

  defp create_script(command, type_lang) do
    %{source: command, lang: type_lang}
  end

  defp get_filter_field(%{terms: %{field: field}}) do
    field
  end

  defp create_query(%{business_concept_id: id}) do
    %{term: %{business_concept_id: id}}
  end
  defp create_query(%{"query" => query}) do
    %{simple_query_string: %{query: query}}
    |> bool_query
  end

  defp create_query(_params) do
    %{match_all: %{}}
    |> bool_query
  end

  defp bool_query(query) do
    %{bool: %{must: query}}
  end
end
