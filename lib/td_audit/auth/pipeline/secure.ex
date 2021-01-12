defmodule TdAudit.Auth.Pipeline.Secure do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :td_audit,
    error_handler: TdAudit.Auth.ErrorHandler,
    module: TdAudit.Auth.Guardian

  plug Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"}
  plug TdAudit.Auth.Plug.CurrentResource
end
