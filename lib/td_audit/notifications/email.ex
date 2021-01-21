defmodule TdAudit.Notifications.Email do
  @moduledoc """
  Provides functions for sending notification emails.
  """
  use Bamboo.Phoenix, view: TdAuditWeb.EmailView

  alias TdAudit.Notifications.Notification
  alias TdAudit.Subscriptions
  alias TdDfLib.RichText

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

  def create(%{recipients: recipients, who: who, uri: uri, resource: resource} = message) do
    headers = Map.get(message, :headers)
    user = Map.get(who, :full_name, "deleted")
    reply_to = Map.get(who, :email, "deleted")
    name = Map.get(resource, "name")
    description = Map.get(resource, "description")

    subject =
      headers
      |> Map.get("subject")
      |> String.replace("(user)", user)
      |> String.replace("(name)", "\"#{name}\"")

    header =
      headers
      |> Map.get("header")
      |> String.replace("(user)", user)

    new_email()
    |> put_html_layout({TdAuditWeb.LayoutView, "email.html"})
    |> put_header("Reply-To", reply_to)
    |> assign(:header, header)
    |> assign(:uri, uri)
    |> assign(:name, name)
    |> assign(:description, description(description))
    |> assign(:description_header, Map.get(headers, "description_header"))
    |> assign(:footer, footer())
    |> assign(:message, Map.get(message, :message))
    |> assign(:message_header, Map.get(headers, "message_header"))
    |> subject(subject)
    |> to(recipients)
    |> from(sender())
    |> render("share.html")
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
  defp template(["concept_rejected"]), do: :concepts
  defp template(["concept_submitted"]), do: :concepts
  defp template(["concept_rejection_canceled"]), do: :concepts
  defp template(["concept_deprecated"]), do: :concepts
  defp template(["concept_published"]), do: :concepts
  defp template(["delete_concept_draft"]), do: :concepts
  defp template(["new_concept_draft"]), do: :concepts
  defp template(["relation_created"]), do: :concepts
  defp template(["relation_deleted"]), do: :concepts
  defp template(["update_concept_draft"]), do: :concepts
  defp template(["relation_deprecated"]), do: :relations

  defp template(events) when length(events) > 1 do
    events
    |> List.delete("relation_deprecated")
    |> Enum.slice(0, 1)
    |> template()
  end

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

  defp description(description = %{}) do
    description
    |> RichText.to_plain_text()
    |> truncate()
  end

  defp description("" = description) do
    truncate(description)
  end

  defp truncate(text, size \\ 90) do
    if String.length(text) > size do
      "#{String.slice(text, 0..size)}..."
    else
      text
    end
  end
end
