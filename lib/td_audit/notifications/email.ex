defmodule TdAudit.Notifications.Email do
  @moduledoc """
  Provides functions for sending notification emails.
  """
  use Bamboo.Phoenix, view: TdAuditWeb.EmailView

  alias TdAudit.Notifications.Notification
  alias TdAudit.Subscriptions

  def create(%Notification{events: events, subscription: subscription} = notification) do
    template = template(notification)
    recipients = Subscriptions.get_recipients(subscription)

    new_email()
    |> put_html_layout({TdAuditWeb.LayoutView, "email.html"})
    |> assign(:header, header(template))
    |> assign(:footer, footer())
    |> assign(:events, events)
    |> subject(subj(template))
    |> to(recipients)
    |> from(sender())
    |> render("events.html")
  end

  defp template(%Notification{events: events}) do
    events
    |> Enum.map(& &1.event)
    |> Enum.uniq()
    |> template()
  end

  defp template(["ingest_sent_for_approval"]), do: :ingests_pending
  defp template(["rule_result_created"]), do: :rule_results
  defp template(["comment_created"]), do: :comments
  defp template(["concept_submitted"]), do: :concept_submitted
  defp template(_), do: :default

  defp config, do: Application.fetch_env!(:td_audit, __MODULE__)

  defp subj(template) do
    config()
    |> get_in([:subjects, template])
  end

  defp header(template) do
    config()
    |> get_in([:headers, template])
  end

  defp footer do
    footer =
      config()
      |> Keyword.fetch!(:footer)

    version = Application.spec(:td_audit, :vsn)
    "#{footer} v#{version}"
  end

  defp sender do
    config()
    |> Keyword.fetch!(:sender)
  end
end
