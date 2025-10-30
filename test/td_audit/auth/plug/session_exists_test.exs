defmodule TdAudit.Auth.Plug.SessionExistsTest do
  use TdAuditWeb.ConnCase

  alias TdAudit.Auth.Plug.SessionExists
  alias TdCache.SessionCache

  setup do
    conn = build_conn()
    %{conn: conn}
  end

  describe "call/2" do
    test "returns conn when session exists", %{conn: conn} do
      jti = "test_jti_#{System.unique_integer([:positive])}"
      exp = System.system_time(:second) + 3600
      SessionCache.put(jti, exp)

      conn =
        conn
        |> Guardian.Plug.put_current_claims(%{"jti" => jti})
        |> SessionExists.call(%{})

      assert conn.status != 401
      refute conn.halted

      SessionCache.delete(jti)
    end

    test "calls unauthorized when session does not exist", %{conn: conn} do
      jti = "nonexistent_jti_#{System.unique_integer([:positive])}"

      conn =
        conn
        |> Guardian.Plug.put_current_claims(%{"jti" => jti})
        |> SessionExists.call(%{})

      assert conn.status == 401
      assert conn.halted
      assert %{"message" => "unauthorized"} = Jason.decode!(conn.resp_body)
    end

    test "calls unauthorized when jti is missing from claims", %{conn: conn} do
      conn =
        conn
        |> Guardian.Plug.put_current_claims(%{})
        |> SessionExists.call(%{})

      assert conn.status == 401
      assert conn.halted
      assert %{"message" => "unauthorized"} = Jason.decode!(conn.resp_body)
    end

    test "calls unauthorized when no claims are present", %{conn: conn} do
      conn = SessionExists.call(conn, %{})

      assert conn.status == 401
      assert conn.halted
      assert %{"message" => "unauthorized"} = Jason.decode!(conn.resp_body)
    end
  end

  describe "init/1" do
    test "returns options unchanged" do
      opts = %{some: :option}
      assert SessionExists.init(opts) == opts
    end
  end
end
