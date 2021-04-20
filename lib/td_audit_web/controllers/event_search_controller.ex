defmodule TdAuditWeb.EventSearchController do
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.Audit
  alias TdAuditWeb.SwaggerDefinitions

  action_fallback(TdAuditWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.event_swagger_definitions()
  end

  swagger_path :create do
    description("Search Events")
    response(200, "OK", Schema.ref(:EventsResponse))
  end

  def create(conn, params) do
    events = Audit.list_events(params)

    conn
    |> put_view(TdAuditWeb.EventView)
    |> render("index.json", events: events)
  end
end
