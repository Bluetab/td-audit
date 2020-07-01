defmodule TdAudit.TestOperators do
  @moduledoc """
  Equality operators for tests
  """

  alias TdAudit.Subscriptions.Subscription

  def a <~> b, do: approximately_equal(a, b)
  def a <|> b, do: approximately_equal(Enum.sort(a), Enum.sort(b))

  ## Equality test for subscriptions without comparing Ecto associations.
  defp approximately_equal(%Subscription{} = a, %Subscription{} = b) do
    Map.drop(a, [:subscriber]) ==
      Map.drop(b, [:subscriber])
  end

  defp approximately_equal([h | t], [h2 | t2]) do
    approximately_equal(h, h2) && approximately_equal(t, t2)
  end

  defp approximately_equal(a, b), do: a == b
end
