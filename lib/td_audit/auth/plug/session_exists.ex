defmodule TdAudit.Auth.Plug.SessionExists do
  @moduledoc """
  A plug to check that the access token has not been revoked.
  """

  alias TdAudit.Auth.ErrorHandler
  alias TdCache.SessionCache

  def init(opts), do: opts

  def call(conn, _opts) do
    with %{"jti" => jti} <- Guardian.Plug.current_claims(conn),
         true <- SessionCache.exists?(jti) do
      conn
    else
      _ -> ErrorHandler.unauthorized(conn)
    end
  end
end
