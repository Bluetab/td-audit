defmodule TdAudit.Search.Aggregations do
  @moduledoc """
    Aggregations for elasticsearch
  """
  def bc_aggregation_terms do
    static_keywords = [
      {"domain", %{terms: %{field: "domain.name.raw"}}},
      {"status", %{terms: %{field: "status"}}},
      {"type", %{terms: %{field: "type"}}}
    ]
    (static_keywords)
    |> Enum.into(%{})
  end
end
