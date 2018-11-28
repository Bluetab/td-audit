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
  require Logger

  def create(to, subject, body) do
    email_account = Application.get_env(:td_audit, :email_account)
    Logger.info(
      "Sending email to #{to} from account #{email_account}"
    )
    new_email()
    |> from(email_account)
    |> to(to)
    |> subject(subject)
    |> html_body(body)
  end
end
