defmodule TdAuditWeb.NotificationController do
  use TdAuditWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

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
        "notification" => %{} = notification
      }) do
    with claims <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(claims, create({Notifications, notification}))},
         %{user_id: user_id} <- claims do
      notification
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.put(:user_id, user_id)
      |> Dispatcher.dispatch()

      send_resp(conn, :accepted, "")
    end
  end

  swagger_path :read do
    description("Read notification")

    parameters do
      id(:path, :integer, "Notification ID", required: true)
    end

    response(200, "OK")
    response(403, "Forbidden")
    response(422, "Client Error")
  end

  def read(conn, %{"id" => id}) do
    with %{user_id: user_id} <- conn.assigns[:current_resource],
         {notification_id, _} <- Integer.parse(id) do
      Notifications.read(notification_id, user_id)
      send_resp(conn, :ok, "")
    end
  end
end
