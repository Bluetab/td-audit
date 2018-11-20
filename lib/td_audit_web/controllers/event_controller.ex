defmodule TdAuditWeb.EventController do
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.Audit
  alias TdAudit.Audit.Event
  alias TdAuditWeb.SwaggerDefinitions

  @filters_availables ["resource_id", "resource_type"]

  action_fallback TdAuditWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.event_swagger_definitions()
  end

  swagger_path :index do
    get "/events"
    description "List Events"
    response 200, "OK", Schema.ref(:EventsResponse)
  end

  def index(conn, params) do
    events =
      case Map.take(params, @filters_availables) do
        empty when empty == %{} -> Audit.list_events()
        params_filtered -> Audit.list_events_by_filter(params_filtered)
      end
    render(conn, "index.json", events: events)
  end

  swagger_path :create do
    post "/events"
    description "Creates Event"
    produces "application/json"
    parameters do
      event :body, Schema.ref(:EventCreate), "Event create attrs"
    end
    response 201, "OK", Schema.ref(:EventResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"event" => event_params}) do
    with {:ok, %Event{} = event} <- Audit.create_event(event_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", event_path(conn, :show, event))
      |> render("show.json", event: event)
    end
  end

  swagger_path :show do
    get "/events/{id}"
    description "Show Event"
    produces "application/json"
    parameters do
      id :path, :integer, "Event ID", required: true
    end
    response 200, "OK", Schema.ref(:EventResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    event = Audit.get_event!(id)
    render(conn, "show.json", event: event)
  end

  swagger_path :update do
    put "/events/{id}"
    description "Update Event"
    produces "application/json"
    parameters do
      id :path, :integer, "Event ID", required: true
      event :body, Schema.ref(:EventUpdate), "Event update attrs"
    end
    response 201, "OK", Schema.ref(:EventResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "event" => event_params}) do
    event = Audit.get_event!(id)

    with {:ok, %Event{} = event} <- Audit.update_event(event, event_params) do
      render(conn, "show.json", event: event)
    end
  end

  swagger_path :delete do
    delete "/events/{id}"
    description "Delete Event"
    produces "application/json"
    parameters do
      id :path, :integer, "Event ID", required: true
    end
    response 204, "No Content"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    event = Audit.get_event!(id)
    with {:ok, %Event{}} <- Audit.delete_event(event) do
      send_resp(conn, :no_content, "")
    end
  end
end
