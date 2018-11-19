defmodule TdAuditWeb.ConfigurationControllerTest do
  use TdAuditWeb.ConnCase

  alias TdAudit.NotificationsSystem
  alias TdAudit.NotificationsSystem.Configuration

  @create_attrs %{configuration: %{}, event: "some event"}
  @update_attrs %{configuration: %{}, event: "some updated event"}
  @invalid_attrs %{configuration: nil, event: nil}

  def fixture(:configuration) do
    {:ok, configuration} = NotificationsSystem.create_configuration(@create_attrs)
    configuration
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all notifications_system_configuration", %{conn: conn} do
      conn = get conn, configuration_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create configuration" do
    test "renders configuration when data is valid", %{conn: conn} do
      conn = post conn, configuration_path(conn, :create), configuration: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, configuration_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "configuration" => %{},
        "event" => "some event"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, configuration_path(conn, :create), configuration: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update configuration" do
    setup [:create_configuration]

    test "renders configuration when data is valid", %{conn: conn, configuration: %Configuration{id: id} = configuration} do
      conn = put conn, configuration_path(conn, :update, configuration), configuration: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, configuration_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "configuration" => %{},
        "event" => "some updated event"}
    end

    test "renders errors when data is invalid", %{conn: conn, configuration: configuration} do
      conn = put conn, configuration_path(conn, :update, configuration), configuration: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete configuration" do
    setup [:create_configuration]

    test "deletes chosen configuration", %{conn: conn, configuration: configuration} do
      conn = delete conn, configuration_path(conn, :delete, configuration)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, configuration_path(conn, :show, configuration)
      end
    end
  end

  defp create_configuration(_) do
    configuration = fixture(:configuration)
    {:ok, configuration: configuration}
  end
end
