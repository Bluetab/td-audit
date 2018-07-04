defmodule TdAuditWeb.EchoController do
  use TdAuditWeb, :controller

  action_fallback TdAuditWeb.FallbackController

  def echo(conn, params) do
    send_resp(conn, 200, params |> Poison.encode!)
  end
end
