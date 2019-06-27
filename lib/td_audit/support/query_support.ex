defmodule TdAudit.QuerySupport do
  @moduledoc """
  Support functions to query in ecto.
  """

  import Ecto.Query, warn: false

  def filter(params, fields) do
    dynamic = true

    Enum.reduce(Map.keys(params), dynamic, fn key, acc ->
      key_as_atom = if is_binary(key), do: String.to_atom(key), else: key

      case Enum.member?(fields, key_as_atom) do
        true -> filter_by_type(key_as_atom, params[key], acc)
        false -> acc
      end
    end)
  end

  defp filter_by_type(:ts = atom_key, %{value: value, filter: :gt}, acc) do
    dynamic([p], field(p, ^atom_key) > ^value and ^acc)
  end

  defp filter_by_type(atom_key, param_value, acc) when is_map(param_value) do
    dynamic([p], fragment("(?) @> ?::jsonb", field(p, ^atom_key), ^param_value) and ^acc)
  end

  defp filter_by_type(atom_key, param_value, acc) do
    dynamic([p], field(p, ^atom_key) == ^param_value and ^acc)
  end
end
