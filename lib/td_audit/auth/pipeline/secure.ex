defmodule TdAudit.Auth.Pipeline.Secure do
  @moduledoc """
  Plug pipeline for routes requiring authentication
  """

  use Guardian.Plug.Pipeline,
    otp_app: :td_audit,
    error_handler: TdAudit.Auth.ErrorHandler,
    module: TdAudit.Auth.Guardian

  plug Guardian.Plug.EnsureAuthenticated, claims: %{"aud" => "truedat", "iss" => "tdauth"}
  plug Guardian.Plug.LoadResource
  plug TdAudit.Auth.Plug.SessionExists
  plug TdAudit.Auth.Plug.CurrentResource
end
