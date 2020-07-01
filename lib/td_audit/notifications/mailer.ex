defmodule TdAudit.Notifications.Mailer do
  @moduledoc """
  Module in charge of sending emails
  """
  use Bamboo.Mailer, otp_app: :td_audit
end
