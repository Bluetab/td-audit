defmodule TdAuditWeb.ScopeView do
  use TdAuditWeb, :view

  def render("scope.json", %{scope: scope}) do
    fields =
      case Map.get(scope, :status) do
        [_ | _] -> [:events, :status, :resource_type, :resource_id]
        _ -> [:events, :resource_type, :resource_id]
      end

    Map.take(scope, fields)
  end
end
