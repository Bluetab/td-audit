defmodule TdAudit.ESClientApi do
  use HTTPoison.Base
  require Logger
  alias Poison, as: JSON

  @moduledoc false
  def search_es(index_name, query) do
    post("#{index_name}/" <> "_search/", query |> JSON.encode!())
  end

  @moduledoc false
  def udapte_by_query(index_name, query) do
    post("#{index_name}/" <> "_update_by_query/", query |> JSON.encode!())
  end
    @doc """
    Concatenates elasticsearch path at the beggining of HTTPoison requests
  """
  def process_url(path) do
    es_config = Application.get_env(:td_audit, :elasticsearch)
    "#{es_config[:es_host]}:#{es_config[:es_port]}/" <> path
  end

  @doc """
    Decodes response body
  """
  def process_response_body(body) do
    body
    |> Poison.decode!()
  end

  @doc """
    Adds requests headers
  """
  def process_request_headers(_headers) do
    headers = [{"Content-Type", "application/json"}]
    headers
  end
end
