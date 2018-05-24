defmodule TdAuditWeb.EventControllerTest do
  use TdAuditWeb.ConnCase

  alias TdAudit.Audit
  alias TdAudit.Audit.Event

  @create_attrs %{event: "some event", payload: %{}, resource_id: 42, resource_type: "some resource_type", service: "some service", ts: "2010-04-17 14:00:00.000000Z", user_id: 42, user_name: "user name"}
  @update_attrs %{event: "some updated event", payload: %{}, resource_id: 43, resource_type: "some updated resource_type", service: "some updated service", ts: "2011-05-18 15:01:01.000000Z", user_id: 43, user_name: "some updated name"}
  @invalid_attrs %{event: nil, payload: nil, resource_id: nil, resource_type: nil, service: nil, ts: nil, user_id: nil, user_name: nil}

  def fixture(:event) do
    {:ok, event} = Audit.create_event(@create_attrs)
    event
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all events", %{conn: conn} do
      conn = get conn, event_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create event" do
    test "renders event when data is valid", %{conn: conn} do
      conn = post conn, event_path(conn, :create), event: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, event_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "event" => "some event",
        "payload" => %{},
        "resource_id" => 42,
        "resource_type" => "some resource_type",
        "service" => "some service",
        "ts" => "2010-04-17T14:00:00.000000Z",
        "user_id" => 42}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, event_path(conn, :create), event: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update event" do
    setup [:create_event]

    test "renders event when data is valid", %{conn: conn, event: %Event{id: id} = event} do
      conn = put conn, event_path(conn, :update, event), event: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, event_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "event" => "some updated event",
        "payload" => %{},
        "resource_id" => 43,
        "resource_type" => "some updated resource_type",
        "service" => "some updated service",
        "ts" => "2011-05-18T15:01:01.000000Z",
        "user_id" => 43}
    end

    test "renders errors when data is invalid", %{conn: conn, event: event} do
      conn = put conn, event_path(conn, :update, event), event: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete event" do
    setup [:create_event]

    test "deletes chosen event", %{conn: conn, event: event} do
      conn = delete conn, event_path(conn, :delete, event)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, event_path(conn, :show, event)
      end
    end
  end

  defp create_event(_) do
    event = fixture(:event)
    {:ok, event: event}
  end
end
