defmodule TdAuditWeb.EventController do
  use TdAuditWeb, :controller

  alias TdAudit.Audit

  @filters_availables ["resource_id", "resource_type", "event", "start_ts", "end_ts"]

  action_fallback(TdAuditWeb.FallbackController)

  def index(conn, params) do
    events =
      case Map.take(params, @filters_availables) do
        empty when empty == %{} -> Audit.list_events()
        params_filtered -> Audit.list_events(params_filtered)
      end

    render(conn, "index.json", events: events)
  end

  def show(conn, %{"id" => id}) do
    event = Audit.get_event!(id)
    render(conn, "show.json", event: event)
  end
end
