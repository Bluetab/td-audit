defmodule TdAuditWeb.EventControllerTest do
  @moduledoc """
  Event testing module
  """
  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuditWeb.Authentication, only: :functions

  alias TdAudit.Audit
  alias TdAudit.Audit.Event
  alias TdAuditWeb.ApiServices.MockTdAuthService

  @create_attrs %{event: "some event", payload: %{}, resource_id: 42, resource_type: "some resource_type", service: "some service", ts: "2010-04-17 14:00:00.000000Z", user_id: 42, user_name: "user name"}
  @update_attrs %{event: "some updated event", payload: %{}, resource_id: 43, resource_type: "some updated resource_type", service: "some updated service", ts: "2011-05-18 15:01:01.000000Z", user_id: 43, user_name: "some updated name"}
  @invalid_attrs %{event: nil, payload: nil, resource_id: nil, resource_type: nil, service: nil, ts: nil, user_id: nil, user_name: nil}

  @admin_user_name "app-admin"

  def fixture(:event) do
    {:ok, event} = Audit.create_event(@create_attrs)
    event
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all events", %{conn: conn, swagger_schema: schema} do
      conn = get conn, event_path(conn, :index)
      validate_resp_schema(conn, schema, "EventsResponse")
      assert json_response(conn, 200)["data"] == []
    end

    @tag authenticated_user: @admin_user_name
    test "lists all events filtered", %{conn: conn, swagger_schema: schema} do
      conn = get conn, event_path(conn, :index, "resource_id": 42, "resource_type": "some resource_type")
      validate_resp_schema(conn, schema, "EventsResponse")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create event" do
    @tag authenticated_user: @admin_user_name
    test "renders event when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, event_path(conn, :create), event: @create_attrs
      validate_resp_schema(conn, schema, "EventResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, event_path(conn, :show, id)
      validate_resp_schema(conn, schema, "EventResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "event" => "some event",
        "payload" => %{},
        "resource_id" => 42,
        "resource_type" => "some resource_type",
        "service" => "some service",
        "ts" => "2010-04-17T14:00:00.000000Z",
        "user_id" => 42,
        "user_name" => "user name"}
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, event_path(conn, :create), event: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update event" do
    setup [:create_event]

    @tag authenticated_user: @admin_user_name
    test "renders event when data is valid", %{conn: conn, event: %Event{id: id} = event, swagger_schema: schema} do
      conn = put conn, event_path(conn, :update, event), event: @update_attrs
      validate_resp_schema(conn, schema, "EventResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, event_path(conn, :show, id)
      validate_resp_schema(conn, schema, "EventResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "event" => "some updated event",
        "payload" => %{},
        "resource_id" => 43,
        "resource_type" => "some updated resource_type",
        "service" => "some updated service",
        "ts" => "2011-05-18T15:01:01.000000Z",
        "user_id" => 43,
        "user_name" => "some updated name"}
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn, event: event} do
      conn = put conn, event_path(conn, :update, event), event: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete event" do
    setup [:create_event]

    @tag authenticated_user: @admin_user_name
    test "deletes chosen event", %{conn: conn, event: event, swagger_schema: schema} do
      conn = delete conn, event_path(conn, :delete, event)
      assert response(conn, 204)

      conn = recycle_and_put_headers(conn)

      assert_error_sent 404, fn ->
        get conn, event_path(conn, :show, event)
        validate_resp_schema(conn, schema, "EventResponse")
      end
    end
  end

  defp create_event(_) do
    event = fixture(:event)
    {:ok, event: event}
  end
end
