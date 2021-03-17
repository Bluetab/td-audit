defmodule TdAudit.QuerySupport do
  @moduledoc """
  Support functions to query in ecto.
  """

  import Ecto.Query, warn: false

  def filter(params, fields) do
    dynamic = true

    params
    |> Enum.map(fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      kv -> kv
    end)
    |> Enum.filter(fn {key, _} -> Enum.member?(fields, key) end)
    |> Enum.reduce(dynamic, fn {key, value}, acc ->
      filter_by_type(key, value, acc)
    end)
  end

  defp filter_by_type(:ts = atom_key, %{value: value, filter: :gt}, acc) do
    dynamic([p], field(p, ^atom_key) > ^value and ^acc)
  end

  defp filter_by_type(:start_ts, value, acc) do
    dynamic([p], field(p, :ts) >= ^value and ^acc)
  end

  defp filter_by_type(:end_ts, value, acc) do
    dynamic([p], field(p, :ts) <= ^value and ^acc)
  end

  defp filter_by_type(atom_key, values, acc) when is_list(values) do
    dynamic([p], field(p, ^atom_key) in ^values and ^acc)
  end

  defp filter_by_type(atom_key, param_value, acc) when is_map(param_value) do
    dynamic([p], fragment("(?) @> ?::jsonb", field(p, ^atom_key), ^param_value) and ^acc)
  end

  defp filter_by_type(atom_key, param_value, acc) do
    dynamic([p], field(p, ^atom_key) == ^param_value and ^acc)
  end
end
