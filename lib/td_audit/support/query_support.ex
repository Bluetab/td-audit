defmodule TdAudit.QuerySupport do
  @moduledoc """
  Support functions to query in ecto.
  """

  import Ecto.Query, warn: false

  def filter(params, fields) do
    dynamic = true
    Enum.reduce(Map.keys(params), dynamic, fn (x, acc) ->
       key_as_atom = String.to_atom(x)
       case Enum.member?(fields, key_as_atom) do
         true -> dynamic([p], field(p, ^key_as_atom) == ^params[x] and ^acc)
         false -> acc
       end
    end)
  end
end
