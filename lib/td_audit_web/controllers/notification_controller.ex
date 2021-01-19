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
    SwaggerDefinitions.subscriber_swagger_definitions()
  end

  swagger_path :create do
    description("Creates a notification")
    produces("application/json")

    parameters do
      subscription(:body, Schema.ref(:NotificationCreate), "Creation attrs of a Notification")
    end

    response(202, "Accepted")
    response(400, "Client Error")
  end

  def create(conn, %{
        "notification" => %{
          "recipients" => recipients,
          "url" => url,
          "message" => message,
          "headers" => headers,
          "name" => name
        }
      }) do
    with %{user_name: user_name} <- conn.assigns[:current_resource] do
      %{}
      |> Map.put(:recipients, recipients)
      |> Map.put(:url, url)
      |> Map.put(:message, message)
      |> Map.put(:who, user_name)
      |> Map.put(:headers, headers)
      |> Map.put(:name, name)
      |> Dispatcher.dispatch()

      send_resp(conn, :accepted, "")
    end
  end
end
