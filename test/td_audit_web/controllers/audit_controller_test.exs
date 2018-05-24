defmodule TdAuditWeb.AuditControllerTest do
  use TdAuditWeb.ConnCase

  @create_attrs %{event: "some event", payload: %{}, resource_id: 42, resource_type: "some resource_type", service: "some service", ts: "2010-04-17 14:00:00.000000Z", user_id: 42, user_name: "user name"}
  @invalid_attrs %{event: nil, payload: nil, resource_id: nil, resource_type: nil, service: nil, ts: nil, user_id: nil, user_name: nil}

  describe "create audit event" do
    test "renders event when data is valid", %{conn: conn} do
      conn = post conn, audit_path(conn, :create), audit: @create_attrs
      assert response(conn, 204)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, audit_path(conn, :create), audit: @invalid_attrs
      assert response(conn, 422)
    end
  end
end
