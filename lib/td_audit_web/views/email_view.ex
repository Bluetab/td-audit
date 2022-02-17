defmodule TdAuditWeb.EmailView do
  use TdAuditWeb, :view

  require Logger

  alias TdAuditWeb.EventView

  def render("ingest_sent_for_approval.html", %{event: event}) do
    render("ingest_sent_for_approval.html",
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      uri: uri(event)
    )
  end

  def render("rule_result_created.html", %{event: %{payload: payload} = event}) do
    values =
      ["goal", "minimum", "errors", "records", "result"]
      |> Enum.map(&{&1, format_number(payload, &1)})
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> {translate(k), v} end)

    render("rule_result_created.html",
      name: EventView.resource_name(event),
      values: values,
      domains: domain_path(event),
      date: TdAudit.Helpers.shift_zone(payload["date"]),
      uri: uri(event)
    )
  end

  def render("comment_created.html", %{event: %{payload: payload} = event}) do
    render("comment_created.html",
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      comment: payload["content"],
      uri: uri(event)
    )
  end

  def render("concept_rejected.html", event), do: render_concepts(event)
  def render("concept_submitted.html", event), do: render_concepts(event)
  def render("concept_rejection_canceled.html", event), do: render_concepts(event)
  def render("concept_deprecated.html", event), do: render_concepts(event)
  def render("concept_published.html", event), do: render_concepts(event)
  def render("delete_concept_draft.html", event), do: render_concepts(event)
  def render("new_concept_draft.html", event), do: render_concepts(event)
  def render("relation_created.html", event), do: render_concepts(event)
  def render("relation_deleted.html", event), do: render_concepts(event)
  def render("update_concept_draft.html", event), do: render_concepts(event)

  def render("relation_deprecated.html", %{event: event}) do
    render("relation_deprecated.html",
      name: EventView.resource_name(event),
      event_name: event_name(event),
      target: relation_side(event),
      domains: domain_path(event),
      target_uri: target_uri(event),
      uri: uri(event)
    )
  end

  def render("structure_note_deleted.html", event), do: render_notes(event)
  def render("structure_note_deprecated.html", event), do: render_notes(event)
  def render("structure_note_draft.html", event), do: render_notes(event)
  def render("structure_note_pending_approval.html", event), do: render_notes(event)
  def render("structure_note_published.html", event), do: render_notes(event)
  def render("structure_note_rejected.html", event), do: render_notes(event)
  def render("structure_note_versioned.html", event), do: render_notes(event)
  def render("structure_tag_linked.html", event), do: render_tag(event)
  def render("structure_tag_link_updated.html", event), do: render_tag(event)
  def render("structure_tag_link_deleted.html", event), do: render_tag(event)

  def render("grant_created.html", event), do: render_grant(event)
  def render("grant_deleted.html", event), do: render_grant(event)

  def render("job_status_started.html", event), do: render_sources(event)
  def render("job_status_pending.html", event), do: render_sources(event)
  def render("job_status_failed.html", event), do: render_sources(event)
  def render("job_status_succeeded.html", event), do: render_sources(event)
  def render("job_status_warning.html", event), do: render_sources(event)
  def render("job_status_info.html", event), do: render_sources(event)

  def render(template, %{event: event}) do
    Logger.warn("Template #{template} not supported")

    event
    |> Map.take([:event, :payload])
    |> Jason.encode!()
  end

  defp render_concepts(%{event: event}) do
    render("concepts.html",
      user: user_name(event),
      name: EventView.resource_name(event),
      event_name: event_name(event),
      domains: domain_path(event),
      uri: uri(event)
    )
  end

  defp render_tag(%{event: event}) do
    render("tag.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      tag: resource_tag(event),
      description: description(event),
      domains: domain_path(event),
      uri: uri(event)
    )
  end

  defp render_notes(%{event: event}) do
    render("notes.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      uri: uri(event)
    )
  end

  defp render_grant(%{event: event}) do
    render("grant.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      start_date: grant_date(event, "start_date"),
      end_date: grant_date(event, "end_date"),
      uri: uri(event)
    )
  end

  defp render_sources(%{event: %{payload: %{"source_external_id" => source_name}} = event}) do
    render("sources.html",
      event_name: event_name(event),
      user: user_name(event),
      name: source_name,
      job_uri: uri(event),
      source_uri: uri(%{event | resource_type: "sources"})
    )
  end

  defp format_number(%{"result_type" => result_type} = payload, key) do
    format =
      if key in ["errors", "records"] do
        "number"
      else
        result_type
      end

    payload
    |> Map.get(key)
    |> format_number(format)
  end

  defp format_number(nil, _), do: nil

  defp format_number(value, "percentage") do
    Number.Percentage.number_to_percentage(value)
  end

  defp format_number(value, _format) do
    Number.Delimit.number_to_delimited(value)
  end

  defp user_name(%{user: %{full_name: full_name}}), do: full_name
  defp user_name(_), do: nil

  defp domain_path(%{payload: %{"domain_ids" => domain_ids}}) do
    buid_domain_path(domain_ids)
  end

  defp domain_path(%{resource_id: resource_id, resource_type: "concept"}) do
    case TdCache.ConceptCache.get(resource_id, :domain_ids) do
      {:ok, [_ | _] = domain_ids} -> buid_domain_path(domain_ids)
      _ -> nil
    end
  end

  defp domain_path(_), do: nil

  defp buid_domain_path(domain_ids) do
    domain_ids
    |> Enum.reverse()
    |> Enum.map(&TdCache.TaxonomyCache.get_domain/1)
    |> Enum.filter(& &1)
    |> Enum.map(& &1.name)
    |> Enum.join(" › ")
  end

  defp uri(event) do
    "#{host_name()}#{EventView.path(event)}"
  end

  defp target_uri(%{payload: %{"target_id" => id, "target_type" => "data_structure"}}) do
    "#{host_name()}/structures/#{id}"
  end

  defp target_uri(_), do: nil

  defp host_name, do: Application.fetch_env!(:td_audit, :host_name)

  defp event_name(%{event: "concept_rejected"}), do: "Concept Rejected"
  defp event_name(%{event: "concept_submitted"}), do: "Concept Sent For Approval"
  defp event_name(%{event: "concept_rejection_canceled"}), do: "Rejection Canceled"
  defp event_name(%{event: "concept_deprecated"}), do: "Concept Deprecated"
  defp event_name(%{event: "concept_published"}), do: "Concept Published"
  defp event_name(%{event: "delete_concept_draft"}), do: "Draft Deleted"
  defp event_name(%{event: "new_concept_draft"}), do: "New Concept Draft"
  defp event_name(%{event: "relation_created"}), do: "Created Relation"
  defp event_name(%{event: "relation_deleted"}), do: "Deleted Relation"
  defp event_name(%{event: "update_concept_draft"}), do: "Concept Draft Updated"
  defp event_name(%{event: "relation_deprecated"}), do: "Relation deprecated"
  defp event_name(%{event: "structure_note_deleted"}), do: "Structure note deleted"
  defp event_name(%{event: "structure_note_deprecated"}), do: "Structure note deprecated"
  defp event_name(%{event: "structure_note_draft"}), do: "Structure note to draft"

  defp event_name(%{event: "structure_note_pending_approval"}),
    do: "Structure note pending approval"

  defp event_name(%{event: "structure_note_published"}), do: "Structure note published"
  defp event_name(%{event: "structure_note_rejected"}), do: "Structure note rejected"
  defp event_name(%{event: "structure_note_versioned"}), do: "Structure note versioned"
  defp event_name(%{event: "structure_tag_linked"}), do: "Structure linked to tag"
  defp event_name(%{event: "structure_tag_link_updated"}), do: "Tag linked to structure updated"
  defp event_name(%{event: "structure_tag_link_deleted"}), do: "Tag linked to structure deleted"

  defp event_name(%{event: "grant_created"}),
    do: "You have been granted access to the corresponding structure"

  defp event_name(%{event: "grant_deleted"}),
    do: "You have been deleted access to the corresponding structure"

  defp event_name(%{event: "job_status_started"}), do: "Job started"
  defp event_name(%{event: "job_status_pending"}), do: "Job pending"
  defp event_name(%{event: "job_status_failed"}), do: "Job failed"
  defp event_name(%{event: "job_status_succeeded"}), do: "Job succeeded"
  defp event_name(%{event: "job_status_warning"}), do: "Job warning"
  defp event_name(%{event: "job_status_info"}), do: "Job info"

  defp translate("goal"), do: "Target"
  defp translate("minimum"), do: "Threshold"
  defp translate("records"), do: "Record Count"
  defp translate("errors"), do: "Error Count"
  defp translate("result"), do: "Result"

  defp relation_side(%{payload: %{"target_id" => id, "target_type" => "data_structure"}}) do
    case TdCache.StructureCache.get(id) do
      {:ok, structure} -> Map.get(structure, :external_id)
      _ -> nil
    end
  end

  defp relation_side(_), do: nil

  defp resource_tag(%{payload: %{"tag" => tag}}), do: tag

  defp resource_tag(_), do: nil

  defp description(%{payload: %{"description" => description}}), do: description

  defp description(_), do: nil

  defp grant_date(%{payload: %{"start_date" => start_date}}, "start_date"), do: start_date

  defp grant_date(%{payload: %{"end_date" => end_date}}, "end_date"), do: end_date
end
