defmodule TdAuditWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  import Plug.Conn

  alias Phoenix.ConnTest
  alias TdAudit.Accounts.Session
  alias TdAudit.Auth.Guardian

  @headers {"Content-type", "application/json"}

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def create_user_auth_conn(%{role: role} = session) do
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(session, %{role: role})
    conn = ConnTest.build_conn()
    conn = put_auth_headers(conn, jwt)
    [conn: conn, jwt: jwt, claims: full_claims, session: session]
  end

  def get_header(token) do
    [@headers, {"authorization", "Bearer #{token}"}]
  end

  def create_session(user_name, opts \\ []) do
    role = Keyword.get(opts, :role, "user")
    is_admin = role === "admin"

    %Session{
      user_id: Integer.mod(:binary.decode_unsigned(user_name), 100_000),
      user_name: user_name,
      role: role,
      is_admin: is_admin
    }
  end
end
