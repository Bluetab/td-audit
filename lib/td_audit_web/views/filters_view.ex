defmodule TdAuditWeb.FiltersView do
  use TdAuditWeb, :view

  def render("filters.json", %{filters: filters}) do
    Map.take(filters, [:template, :content])
  end
end
