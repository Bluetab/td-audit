defmodule TdAudit.Notifications.Email do
  @moduledoc """
  Provides functions for sending notification emails.
  """
  use Bamboo.Phoenix, view: TdAuditWeb.EmailView

  alias TdAudit.Notifications
  alias TdAudit.Notifications.Notification
  alias TdAudit.Support.NoteEventsAggregator
  alias TdDfLib.RichText

  def create(%Notification{} = notification) do
    template = template(notification)
    create(notification, template)
  end

  def create(%{recipients: []}) do
    {:error, :no_recipients}
  end

  def create(%{recipients: recipients, who: who, uri: uri, resource: resource} = message) do
    headers = Map.get(message, :headers, %{})
    user = Map.get(who, :full_name, "deleted")
    reply_to = Map.get(who, :email, "deleted")
    name = Map.get(resource, "name")
    description = Map.get(resource, "description")

    subject =
      headers
      |> Map.get("subject")
      |> subject_from_headers(user, name)

    header =
      headers
      |> Map.get("header")
      |> header_from_headers(user)

    email =
      new_email()
      |> put_html_layout({TdAuditWeb.LayoutView, "email.html"})
      |> put_header("Reply-To", reply_to)
      |> assign(:header, header)
      |> assign(:uri, uri)
      |> assign(:name, name)
      |> assign(:description, description(description))
      |> assign(:description_header, Map.get(headers, "description_header", "Description"))
      |> assign(:footer, footer())
      |> assign(:message, Map.get(message, :message))
      |> assign(:message_header, Map.get(headers, "message_header", "Message"))
      |> subject(subject)
      |> to(recipients)
      |> from(sender())
      |> render("share.html")

    {:ok, email}
  end

  def create(%Notification{events: events} = notification, template) when template in [:grants] do
    events
    |> Enum.map(fn %{payload: %{"user_id" => user_id}} = event ->
      with true <- Enum.member?(notification.recipient_ids, user_id),
           [_ | _] = recipients <- Notifications.list_recipients(%{recipient_ids: [user_id]}) do
        new_email()
        |> put_html_layout({TdAuditWeb.LayoutView, "email.html"})
        |> assign(:header, header(template))
        |> assign(:footer, footer())
        |> assign(:events, [event])
        |> subject(subj(template))
        |> to(recipients)
        |> from(sender())
        |> render("events.html")
      else
        _ -> nil
      end
    end)
    |> Enum.filter(&(!is_nil(&1)))
    |> case do
      [] -> {:error, :no_recipients}
      mails -> {:ok, mails}
    end
  end

  def create(%Notification{events: events} = notification, template) do
    case Notifications.list_recipients(notification) do
      [] ->
        {:error, :no_recipients}

      recipients ->
        events = NoteEventsAggregator.maybe_group_events(events)

        email =
          new_email()
          |> put_html_layout({TdAuditWeb.LayoutView, "email.html"})
          |> assign(:header, header(template))
          |> assign(:footer, footer())
          |> assign(:events, events)
          |> subject(subj(template))
          |> to(recipients)
          |> from(sender())
          |> render("events.html")

        {:ok, email}
    end
  end

  defp template(%Notification{events: events}) do
    events
    |> Enum.map(&template(&1.event))
    |> Enum.uniq()
    |> maybe_default_template()
  end

  defp template("comment_created"), do: :comments
  defp template("concept_deprecated"), do: :concepts
  defp template("concept_published"), do: :concepts
  defp template("concept_rejected"), do: :concepts
  defp template("concept_rejection_canceled"), do: :concepts
  defp template("concept_submitted"), do: :concepts
  defp template("delete_concept_draft"), do: :concepts
  defp template("new_concept_draft"), do: :concepts
  defp template("relation_created"), do: :concepts
  defp template("relation_deleted"), do: :concepts
  defp template("update_concept_draft"), do: :concepts
  defp template("grant_approval"), do: :grant_approval
  defp template("grant_created"), do: :grants
  defp template("grant_deleted"), do: :grants
  defp template("grant_request_approval_addition"), do: :grant_request_approvals
  defp template("grant_request_approval_consensus"), do: :grant_request_approvals
  defp template("grant_request_rejection"), do: :grant_request_approvals
  defp template("grant_request_group_creation"), do: :grant_request_group_creation
  defp template("grant_request_status_cancellation"), do: :grant_request_status
  defp template("grant_request_status_failure"), do: :grant_request_status
  defp template("grant_request_status_process_end"), do: :grant_request_status
  defp template("grant_request_status_process_start"), do: :grant_request_status
  defp template("implementation_created"), do: :implementations
  defp template("implementation_status_updated"), do: :implementations
  defp template("ingest_sent_for_approval"), do: :ingests_pending
  defp template("job_status_failed"), do: :sources
  defp template("job_status_info"), do: :sources
  defp template("job_status_pending"), do: :sources
  defp template("job_status_started"), do: :sources
  defp template("job_status_succeeded"), do: :sources
  defp template("job_status_warning"), do: :sources
  defp template("relation_deprecated"), do: :relations
  defp template("remediation_created"), do: :remediation_created
  defp template("rule_created"), do: :rules
  defp template("rule_result_created"), do: :rule_results
  defp template("structure_note_deleted"), do: :notes
  defp template("structure_note_deprecated"), do: :notes
  defp template("structure_note_draft"), do: :notes
  defp template("structure_note_pending_approval"), do: :notes
  defp template("structure_note_published"), do: :notes
  defp template("structure_note_rejected"), do: :notes
  defp template("structure_note_updated"), do: :notes
  defp template("structure_note_versioned"), do: :notes
  defp template("structure_tag_link_deleted"), do: :tags
  defp template("structure_tag_link_updated"), do: :tags
  defp template("structure_tag_linked"), do: :tags
  defp template(_), do: :default

  defp maybe_default_template([template]), do: template
  defp maybe_default_template(_), do: :default

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

  defp description(%{} = description) do
    description
    |> RichText.to_plain_text()
    |> truncate()
  end

  defp description(description) when is_binary(description) do
    truncate(description)
  end

  defp description(description), do: description

  defp subject_from_headers(nil, user, name), do: "#{user} has shared \"#{name}\" with you"

  defp subject_from_headers(subject, user, name) do
    subject
    |> String.replace("(user)", user)
    |> String.replace("(name)", "\"#{name}\"")
  end

  defp header_from_headers(nil, user), do: "#{user} has shared a page with you"

  defp header_from_headers(header, user) do
    String.replace(header, "(user)", user)
  end

  defp truncate(text, size \\ 90) do
    if String.length(text) > size do
      "#{String.slice(text, 0..size)}..."
    else
      text
    end
  end
end
