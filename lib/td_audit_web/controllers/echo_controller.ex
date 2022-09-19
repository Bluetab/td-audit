defmodule TdAuditWeb.EchoController do
  use TdAuditWeb, [:controller, :warn]

  action_fallback(TdAuditWeb.FallbackController)

  def echo(conn, params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, Jason.encode!(params))
  end
end
