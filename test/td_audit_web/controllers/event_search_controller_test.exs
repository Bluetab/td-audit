defmodule TdAuditWeb.EventSearchControllerTest do
  @moduledoc """
  Test for `TdAuditWeb.EventController`.
  """

  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  @admin_user_name "app-admin"

  setup %{conn: conn} do
    [conn: put_req_header(conn, "accept", "application/json")]
  end

  describe "GET /api/search/events" do
    @tag authenticated_user: @admin_user_name
    test "lists all events", %{conn: conn, swagger_schema: schema} do
      insert(:event)
      insert(:event, resource_type: "auth")
      %{id: edi1} = insert(:event, resource_type: "auth", event: "login_attempt")
      %{id: edi2} = insert(:event, resource_type: "auth", event: "login_success")
      params = %{"resource_type" => "auth", "event" => ["login_attempt", "login_success"]}

      assert %{"data" => data} =
               conn
               |> post(Routes.event_search_path(conn, :create), params)
               |> validate_resp_schema(schema, "EventsResponse")
               |> json_response(:ok)

      assert [%{"id" => ^edi2}, %{"id" => ^edi1}] = data
    end
  end
end
