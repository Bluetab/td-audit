defmodule TdAuditWeb.ConfigurationController do
  @moduledoc """
  Controller for the configuration of the notifications system
  """
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.NotificationsSystem
  alias TdAudit.NotificationsSystem.Configuration
  alias TdAuditWeb.SwaggerDefinitions

  action_fallback(TdAuditWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.configuration_swagger_definitions()
  end

  swagger_path :index do
    description("List of configurations in our notification system")
    response(200, "OK", Schema.ref(:ConfigurationsResponse))
  end

  def index(conn, _params) do
    notifications_system_configuration =
      NotificationsSystem.list_notifications_system_configuration()

    render(conn, "index.json",
      notifications_system_configuration: notifications_system_configuration
    )
  end

  swagger_path :create do
    description("Creates a Configuration for the notifications system")
    produces("application/json")

    parameters do
      configuration(:body, Schema.ref(:ConfigurationCreate), "Configuration create attrs")
    end

    response(201, "OK", Schema.ref(:ConfigurationResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"configuration" => configuration_params}) do
    with {:ok, %Configuration{} = configuration} <-
           NotificationsSystem.create_configuration(configuration_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.configuration_path(conn, :show, configuration))
      |> render("show.json", configuration: configuration)
    end
  end

  swagger_path :show do
    description("Show a Configuration from a give id")
    produces("application/json")

    parameters do
      id(:path, :integer, "Configuration ID", required: true)
    end

    response(200, "OK", Schema.ref(:ConfigurationResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    configuration = NotificationsSystem.get_configuration!(id)
    render(conn, "show.json", configuration: configuration)
  end

  swagger_path :update do
    description("Update a Configuration from a given")
    produces("application/json")

    parameters do
      id(:path, :integer, "Configuration ID", required: true)
      event(:body, Schema.ref(:ConfigurationUpdate), "Configuration update attrs")
    end

    response(201, "OK", Schema.ref(:ConfigurationResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "configuration" => configuration_params}) do
    configuration = NotificationsSystem.get_configuration!(id)

    with {:ok, %Configuration{} = configuration} <-
           NotificationsSystem.update_configuration(configuration, configuration_params) do
      render(conn, "show.json", configuration: configuration)
    end
  end

  swagger_path :delete do
    description("Delete a Configuration from a given ID")
    produces("application/json")

    parameters do
      id(:path, :integer, "Configuration ID", required: true)
    end

    response(204, "No Content")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    configuration = NotificationsSystem.get_configuration!(id)

    with {:ok, %Configuration{}} <- NotificationsSystem.delete_configuration(configuration) do
      send_resp(conn, :no_content, "")
    end
  end
end
