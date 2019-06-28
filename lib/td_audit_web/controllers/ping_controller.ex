defmodule TdAuditWeb.EchoController do

  use TdAuditWeb, [:controller, :warn]

  alias Jason, as: JSON

  action_fallback(TdAuditWeb.FallbackController)

  def echo(conn, params) do
    send_resp(conn, 200, params |> Jason.encode!())
  end
end
