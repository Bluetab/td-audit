defmodule TdAuditWeb.EventSearchController do
  use TdAuditWeb, :controller

  alias TdAudit.Audit

  action_fallback(TdAuditWeb.FallbackController)

  def create(conn, params) do
    events = Audit.list_events(params)

    conn
    |> put_view(TdAuditWeb.EventView)
    |> render("index.json", events: events)
  end
end
