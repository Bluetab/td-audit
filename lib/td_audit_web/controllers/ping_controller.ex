defmodule TdAuditWeb.PingController do
  use TdAuditWeb, :controller

  action_fallback TdAuditWeb.FallbackController

  def ping(conn, _params) do
    send_resp(conn, 200, "pong")
  end
end
