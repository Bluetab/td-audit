defmodule TdAuditWeb.NotificationController do
  @moduledoc """
  Controller for the subscribers of the system
  """
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.Notifications.Dispatcher
  alias TdAuditWeb.SwaggerDefinitions

  action_fallback(TdAuditWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.notification_swagger_definitions()
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
          "name" => name
        }
      }) do
    with %{user_id: user_id} <- conn.assigns[:current_resource] do
      %{}
      |> Map.put(:recipients, recipients)
      |> Map.put(:uri, uri)
      |> Map.put(:message, message)
      |> Map.put(:user_id, user_id)
      |> Map.put(:headers, headers)
      |> Map.put(:name, name)
      |> Dispatcher.dispatch()

      send_resp(conn, :accepted, "")
    end
  end
end
