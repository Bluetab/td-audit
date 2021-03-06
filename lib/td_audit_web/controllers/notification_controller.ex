defmodule TdAuditWeb.NotificationController do
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.Notifications
  alias TdAudit.Notifications.Dispatcher
  alias TdAuditWeb.SwaggerDefinitions

  action_fallback(TdAuditWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.notification_swagger_definitions()
  end

  swagger_path :index_by_user do
    description("Get logged user notifications")
    produces("application/json")

    response(200, "OK", Schema.ref(:NotificationsResponse))
    response(403, "Forbidden")
    response(422, "Client Error")
  end

  def index_by_user(conn, _params) do
    with %{user_id: user_id} <- conn.assigns[:current_resource] do
      notifications = Notifications.list_notifications(user_id)
      render(conn, "index.json", notifications: notifications)
    end
  end

  swagger_path :create do
    description("Creates a notification")
    produces("application/json")

    parameters do
      notification(:body, Schema.ref(:NotificationCreate), "Creation attrs of a Notification")
    end

    response(202, "Accepted")
    response(400, "Client Error")
  end

  def create(conn, %{
        "notification" => %{
          "recipients" => recipients,
          "uri" => uri,
          "message" => message,
          "headers" => headers,
          "resource" => resource
        }
      }) do
    with %{user_id: user_id} <- conn.assigns[:current_resource] do
      %{}
      |> Map.put(:recipients, recipients)
      |> Map.put(:uri, uri)
      |> Map.put(:message, message)
      |> Map.put(:user_id, user_id)
      |> Map.put(:headers, headers)
      |> Map.put(:resource, resource)
      |> Dispatcher.dispatch()

      send_resp(conn, :accepted, "")
    end
  end
end
