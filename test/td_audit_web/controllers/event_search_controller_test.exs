defmodule TdAuditWeb.EventSearchControllerTest do
  @moduledoc """
  Test for `TdAuditWeb.EventController`.
  """

  use TdAuditWeb.ConnCase

  @admin_user_name "app-admin"

  setup %{conn: conn} do
    [conn: put_req_header(conn, "accept", "application/json")]
  end

  describe "GET /api/search/events" do
    @tag authenticated_user: @admin_user_name
    test "lists all events", %{conn: conn} do
      insert(:event)
      insert(:event, resource_type: "auth")
      %{id: edi1} = insert(:event, resource_type: "auth", event: "login_attempt")
      %{id: edi2} = insert(:event, resource_type: "auth", event: "login_success")
      params = %{"resource_type" => "auth", "event" => ["login_attempt", "login_success"]}

      assert %{"data" => data} =
               conn
               |> post(Routes.event_search_path(conn, :create), params)
               |> json_response(:ok)

      assert [%{"id" => ^edi2}, %{"id" => ^edi1}] = data
    end

    @tag authenticated_user: @admin_user_name
    test "lists events by page", %{conn: conn} do
      insert(:event)
      insert(:event, resource_type: "auth")

      chunk1 =
        1..20
        |> Enum.map(fn _ -> insert(:event, resource_type: "auth", event: "login_attempt") end)
        |> Enum.map(&Map.get(&1, :id))

      chunk2 =
        21..40
        |> Enum.map(fn _ -> insert(:event, resource_type: "auth", event: "login_success") end)
        |> Enum.map(&Map.get(&1, :id))

      params = %{
        "resource_type" => "auth",
        "event" => ["login_attempt", "login_success"],
        "cursor" => %{"size" => 20}
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.event_search_path(conn, :create), params)
               |> json_response(:ok)

      assert chunk1 == Enum.map(data, &Map.get(&1, "id"))

      id = List.last(chunk1)

      params = %{
        "resource_type" => "auth",
        "event" => ["login_attempt", "login_success"],
        "cursor" => %{"size" => 20, "id" => id}
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.event_search_path(conn, :create), params)
               |> json_response(:ok)

      assert chunk2 == Enum.map(data, &Map.get(&1, "id"))
    end
  end
end
