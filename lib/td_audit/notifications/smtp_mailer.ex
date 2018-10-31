defmodule TdAudit.Smtp.Mailer do
  @moduledoc """
  Module in charge of sending emails
  """
  use Bamboo.Mailer, otp_app: :td_audit
end

defmodule TdAudit.EmailBuilder do
  @moduledoc """
  Builds an email
  """
  import Bamboo.Email
  @email_account Application.get_env(:td_audit, :email_account)

  def create(to, subject, body) do
    new_email()
    |> from(@email_account)
    |> to(to)
    |> subject(subject)
    |> html_body(body)
  end
end
