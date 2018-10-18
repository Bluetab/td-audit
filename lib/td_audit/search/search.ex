defmodule TdAudit.Search do

  require Logger
  alias TdAudit.ESClientApi

  @moduledoc """
    Search Engine calls
  """

  def udapte_by_query(index_name, query) do
    response = ESClientApi.udapte_by_query(index_name, query)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Updated index #{index_name} with status #{status}"
      {:error, _error} ->
        Logger.error "ES: Error updating index #{index_name}"
    end
  end

  def get_filters(query) do
    response = ESClientApi.search_es("business_concept", query)
    case response do
      {:ok, %HTTPoison.Response{body: %{"aggregations" => aggretations}}} ->
        aggretations
          |> Map.to_list
          |> Enum.map(&filter_values/1)
          |> Enum.into(%{})
      {:ok, %HTTPoison.Response{body: error}} ->
        error
    end
  end

  defp filter_values({name, %{"buckets" => buckets}}) do
    {name, buckets |> Enum.map(&(&1["key"]))}
  end

end