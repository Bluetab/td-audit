defmodule TdAuditWeb.ConfigurationController do
  use TdAuditWeb, :controller

  alias TdAudit.NotificationsSystem
  alias TdAudit.NotificationsSystem.Configuration

  action_fallback TdAuditWeb.FallbackController

  def index(conn, _params) do
    notifications_system_configuration = NotificationsSystem.list_notifications_system_configuration()
    render(conn, "index.json", notifications_system_configuration: notifications_system_configuration)
  end

  def create(conn, %{"configuration" => configuration_params}) do
    with {:ok, %Configuration{} = configuration} <- NotificationsSystem.create_configuration(configuration_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", configuration_path(conn, :show, configuration))
      |> render("show.json", configuration: configuration)
    end
  end

  def show(conn, %{"id" => id}) do
    configuration = NotificationsSystem.get_configuration!(id)
    render(conn, "show.json", configuration: configuration)
  end

  def update(conn, %{"id" => id, "configuration" => configuration_params}) do
    configuration = NotificationsSystem.get_configuration!(id)

    with {:ok, %Configuration{} = configuration} <- NotificationsSystem.update_configuration(configuration, configuration_params) do
      render(conn, "show.json", configuration: configuration)
    end
  end

  def delete(conn, %{"id" => id}) do
    configuration = NotificationsSystem.get_configuration!(id)
    with {:ok, %Configuration{}} <- NotificationsSystem.delete_configuration(configuration) do
      send_resp(conn, :no_content, "")
    end
  end
end
