defmodule TdAuditWeb.ConfigurationControllerTest do
  @moduledoc """
  Test configuration controller
  """
  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAudit.NotificationsSystem
  alias TdAudit.NotificationsSystem.Configuration
  alias TdAuditWeb.ApiServices.MockTdAuthService

  import TdAuditWeb.Authentication, only: :functions

  @admin_user_name "app-admin"
  @create_attrs %{configuration: %{}, event: "some event"}
  @update_attrs %{configuration: %{}, event: "some updated event"}
  @invalid_attrs %{configuration: nil, event: nil}

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  def fixture(:configuration) do
    {:ok, configuration} = NotificationsSystem.create_configuration(@create_attrs)
    configuration
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all notifications_system_configuration", %{conn: conn, swagger_schema: schema} do
      conn = get conn, configuration_path(conn, :index)
      validate_resp_schema(conn, schema, "ConfigurationsResponse")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create configuration" do
    @tag authenticated_user: @admin_user_name
    test "renders configuration when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, configuration_path(conn, :create), configuration: @create_attrs
      validate_resp_schema(conn, schema, "ConfigurationResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, configuration_path(conn, :show, id)
      validate_resp_schema(conn, schema, "ConfigurationResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "configuration" => %{},
        "event" => "some event"}
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, configuration_path(conn, :create), configuration: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update configuration" do
    setup [:create_configuration]

    @tag authenticated_user: @admin_user_name
    test "renders configuration when data is valid", %{conn: conn, configuration: %Configuration{id: id} = configuration, swagger_schema: schema} do
      conn = put conn, configuration_path(conn, :update, configuration), configuration: @update_attrs
      validate_resp_schema(conn, schema, "ConfigurationResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, configuration_path(conn, :show, id)
      validate_resp_schema(conn, schema, "ConfigurationResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "configuration" => %{},
        "event" => "some updated event"}
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn, configuration: configuration} do
      conn = put conn, configuration_path(conn, :update, configuration), configuration: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete configuration" do
    setup [:create_configuration]

    @tag authenticated_user: @admin_user_name
    test "deletes chosen configuration", %{conn: conn, configuration: configuration, swagger_schema: schema} do
      conn = delete conn, configuration_path(conn, :delete, configuration)
      assert response(conn, 204)

      conn = recycle_and_put_headers(conn)

      assert_error_sent 404, fn ->
        get conn, configuration_path(conn, :show, configuration)
        validate_resp_schema(conn, schema, "ConfigurationResponse")
      end
    end
  end

  defp create_configuration(_) do
    configuration = fixture(:configuration)
    {:ok, configuration: configuration}
  end
end
