defmodule TdAudit.Auth.Plug.CurrentResource do
  @moduledoc """
  A plug to assign claims to the :current_resource key in the connection
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    claims = Guardian.Plug.current_resource(conn)
    assign(conn, :current_resource, claims)
  end
end
