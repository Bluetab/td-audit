defmodule TdAuditWeb.EventControllerTest do
  @moduledoc """
  Test for `TdAuditWeb.EventController`.
  """

  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  @admin_user_name "app-admin"

  setup %{conn: conn} do
    [conn: put_req_header(conn, "accept", "application/json")]
  end

  describe "GET /api/events" do
    @tag authenticated_user: @admin_user_name
    test "lists all events", %{conn: conn, swagger_schema: schema} do
      %{id: id} = insert(:event)

      assert %{"data" => data} =
               conn
               |> get(Routes.event_path(conn, :index))
               |> validate_resp_schema(schema, "EventsResponse")
               |> json_response(:ok)

      assert [%{"id" => ^id}] = data
    end

    @tag authenticated_user: @admin_user_name
    test "lists all events filtered", %{conn: conn, swagger_schema: schema} do
      %{id: id, resource_type: resource_type, resource_id: resource_id} = insert(:event)

      assert %{"data" => data} =
               conn
               |> get(
                 Routes.event_path(conn, :index,
                   resource_id: resource_id,
                   resource_type: resource_type
                 )
               )
               |> validate_resp_schema(schema, "EventsResponse")
               |> json_response(:ok)

      assert [%{"id" => ^id}] = data
    end

    @tag authenticated_user: @admin_user_name
    test "lists all events filtered by event type", %{conn: conn, swagger_schema: schema} do
      %{id: id} = insert(:event, event: "event_type_1")
     insert(:event, event: "event_type_2")

      assert %{"data" => data} =
               conn
               |> get(
                 Routes.event_path(conn, :index,
                   event: "event_type_1"
                 )
               )
               |> validate_resp_schema(schema, "EventsResponse")
               |> json_response(:ok)

      assert [%{"id" => ^id}] = data
    end

    @tag authenticated_user: @admin_user_name
    test "lists all events filtered by range timestamp", %{conn: conn, swagger_schema: schema} do
      %{id: id1} = insert(:event, event: "event_type_ts1", ts: "2021-02-02T00:00:00Z")
      %{id: id2} = insert(:event, event: "event_type_ts2", ts: "2021-02-03T00:00:00Z")

      assert %{"data" => data} =
              conn
              |> get(
                Routes.event_path(conn, :index,
                ts: %{between: ["2021-02-02", "2021-02-03"]}
                )
              )
              |> validate_resp_schema(schema, "EventsResponse")
              |> json_response(:ok)

      assert [%{"id" => ^id1}, %{"id" => ^id2}] = data

    end
  end
end
