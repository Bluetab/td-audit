defmodule TdAuditWeb.ScopeView do
  use TdAuditWeb, :view

  alias TdAuditWeb.FiltersView

  def render("scope.json", %{scope: scope}) do
    fields =
      case Map.get(scope, :status) do
        [_ | _] -> [:events, :status, :resource_type, :resource_id]
        _ -> [:events, :resource_type, :resource_id]
      end

    scope
    |> Map.take(fields)
    |> with_filters(scope)
  end

  defp with_filters(scope, %{filters: %{} = filters}) do
    filters = render_one(filters, FiltersView, "filters.json")
    Map.put(scope, :filters, filters)
  end

  defp with_filters(scope, _), do: scope
end
