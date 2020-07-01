defmodule TdAuditWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  import TdAuditWeb.Authentication, only: :functions

  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.ConnTest

  @admin_user_name "app-admin"

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import TdAudit.Factory

      alias TdAuditWeb.Router.Helpers, as: Routes

      @endpoint TdAuditWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TdAudit.Repo)

    unless tags[:async] do
      Sandbox.mode(TdAudit.Repo, {:shared, self()})
    end

    {:ok, conn: ConnTest.build_conn()}

    cond do
      tags[:admin_authenticated] ->
        @admin_user_name
        |> find_or_create_user(is_admin: true)
        |> create_user_auth_conn()

      tags[:authenticated_user] ->
        @admin_user_name
        |> find_or_create_user(is_admin: false)
        |> create_user_auth_conn()

      true ->
        {:ok, conn: ConnTest.build_conn()}
    end
  end
end
