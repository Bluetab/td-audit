defmodule TdAuditWeb.EchoController do
  use TdAuditWeb, [:controller, :warn]

  action_fallback(TdAuditWeb.FallbackController)

  def echo(conn, params) do
    send_resp(conn, 200, Jason.encode!(params))
  end
end
