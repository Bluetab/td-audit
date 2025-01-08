defmodule TdAuditWeb.NotificationController do
  use TdAuditWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAudit.Notifications
  alias TdAudit.Notifications.Dispatcher

  action_fallback(TdAuditWeb.FallbackController)

  def index_by_user(conn, _params) do
    with %{user_id: user_id} <- conn.assigns[:current_resource] do
      notifications = Notifications.list_notifications(user_id)
      render(conn, "index.json", notifications: notifications)
    end
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

  def read(conn, %{"id" => id}) do
    with %{user_id: user_id} <- conn.assigns[:current_resource],
         {notification_id, _} <- Integer.parse(id) do
      Notifications.read(notification_id, user_id)
      send_resp(conn, :ok, "")
    end
  end
end
