defmodule TdAuditWeb.EventController do
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.Audit
  alias TdAuditWeb.SwaggerDefinitions

  @filters_availables ["resource_id", "resource_type"]

  action_fallback(TdAuditWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.event_swagger_definitions()
  end

  swagger_path :index do
    description("List Events")
    response(200, "OK", Schema.ref(:EventsResponse))
  end

  def index(conn, params) do
    events =
      case Map.take(params, @filters_availables) do
        empty when empty == %{} -> Audit.list_events()
        params_filtered -> Audit.list_events(params_filtered)
      end

    render(conn, "index.json", events: events)
  end

  swagger_path :show do
    description("Show Event")
    produces("application/json")

    parameters do
      id(:path, :integer, "Event ID", required: true)
    end

    response(200, "OK", Schema.ref(:EventResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    event = Audit.get_event!(id)
    render(conn, "show.json", event: event)
  end
end
