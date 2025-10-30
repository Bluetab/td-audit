defmodule TdAudit.Auth.Plug.CurrentResourceTest do
  use TdAuditWeb.ConnCase

  alias TdAudit.Auth.Plug.CurrentResource

  setup do
    conn = build_conn()
    %{conn: conn}
  end

  describe "call/2" do
    test "assigns current_resource from Guardian claims", %{conn: conn} do
      claims = %{user_id: 123, user_name: "test_user", role: "admin"}

      conn =
        conn
        |> Guardian.Plug.put_current_resource(claims)
        |> CurrentResource.call(%{})

      assert conn.assigns.current_resource == claims
    end

    test "assigns nil when no current resource in Guardian", %{conn: conn} do
      conn = CurrentResource.call(conn, %{})

      assert conn.assigns.current_resource == nil
    end

    test "preserves other assigns", %{conn: conn} do
      claims = %{user_id: 456}

      conn =
        conn
        |> Plug.Conn.assign(:other_key, "other_value")
        |> Guardian.Plug.put_current_resource(claims)
        |> CurrentResource.call(%{})

      assert conn.assigns.current_resource == claims
      assert conn.assigns.other_key == "other_value"
    end
  end

  describe "init/1" do
    test "returns options unchanged" do
      opts = %{some: :option}
      assert CurrentResource.init(opts) == opts
    end
  end
end
