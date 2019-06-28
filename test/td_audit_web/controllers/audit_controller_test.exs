defmodule TdAuditWeb.AuditControllerTest do
  use TdAuditWeb.ConnCase

  import TdAuditWeb.Authentication, only: :functions

  alias TdAuditWeb.ApiServices.MockAuthService

  @create_attrs %{
    event: "some event",
    payload: %{},
    resource_id: 42,
    resource_type: "some resource_type",
    service: "some service",
    ts: "2010-04-17 14:00:00Z",
    user_id: 42,
    user_name: "user name"
  }
  @invalid_attrs %{
    event: nil,
    payload: nil,
    resource_id: nil,
    resource_type: nil,
    service: nil,
    ts: nil,
    user_id: nil,
    user_name: nil
  }

  @admin_user_name "app-admin"

  setup_all do
    start_supervised(MockAuthService)
    :ok
  end

  describe "create audit event" do
    @tag authenticated_user: @admin_user_name
    test "renders event when data is valid", %{conn: conn} do
      conn = post(conn, Routes.audit_path(conn, :create), audit: @create_attrs)
      assert response(conn, 201)

      conn = recycle_and_put_headers(conn)

      conn = get(conn, Routes.event_path(conn, :index))

      event_id =
        conn
        |> json_response(200)
        |> Map.get("data")
        |> List.first()
        |> Map.get("id")

      conn = recycle_and_put_headers(conn)

      conn = get(conn, Routes.event_path(conn, :show, event_id))

      assert json_response(conn, 200)["data"] ==
               %{
                 "event" => "some event",
                 "id" => event_id,
                 "payload" => %{},
                 "resource_id" => 42,
                 "resource_type" => "some resource_type",
                 "service" => "some service",
                 "ts" => "2010-04-17T14:00:00.000000Z",
                 "user_id" => 42,
                 "user_name" => "user name"
               }
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.audit_path(conn, :create), audit: @invalid_attrs)
      assert response(conn, 422)
    end
  end
end
