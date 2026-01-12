defmodule TdAuditWeb.EmailView do
  use TdAuditWeb, :view

  require Logger

  alias TdAuditWeb.EventView

  @event_name_to_message %{
    "grant_request_group_creation" => "Grant request for the following structures:",
    "grant_request_approval_addition" => "Grant request approval addition",
    "grant_request_rejection" => "Grant request rejection",
    "grant_request_approval_consensus" => "All approvers acceptance",
    "grant_request_status_process_start" => "Grant request is being processed",
    "grant_request_status_process_end" => "Grant request processing finished",
    "grant_request_status_cancellation" => "Grant request cancellation",
    "grant_request_status_failure" => "Grant request processing failed"
  }

  def render("implementation_created.html", %{event: event}) do
    render("implementation.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      uri: uri(event)
    )
  end

  def render("implementation_status_updated.html", event), do: render_implementation(event)

  def render("ingest_sent_for_approval.html", %{event: event}) do
    render("ingest_sent_for_approval.html",
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      uri: uri(event)
    )
  end

  def render("remediation_created.html", %{event: %{payload: payload} = event}) do
    render("remediation_created.html",
      event_name: event_name(event),
      implementation_key: Map.get(payload, "implementation_key"),
      date: TdAudit.Helpers.shift_zone(payload["date"]),
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
      message: Map.get(payload, "message"),
      domains: domain_path(event),
      date: TdAudit.Helpers.shift_zone(payload["date"]),
      uri: uri(event)
    )
  end

  def render("rule_created.html", %{event: event}) do
    render("rule.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
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
  def render("structure_note_updated.html", event), do: render_notes(event)
  def render("structure_tag_linked.html", event), do: render_tag(event)
  def render("structure_tag_link_updated.html", event), do: render_tag(event)
  def render("structure_tag_link_deleted.html", event), do: render_tag(event)

  def render("grant_approval.html", event), do: render_grant_approval(event)
  def render("grant_created.html", event), do: render_grant(event)
  def render("grant_deleted.html", event), do: render_grant(event)

  def render("grant_request_group_creation.html", %{event: %{event: event_name} = event}) do
    render("grant_request_group_creation.html",
      user: user_name(event),
      group_link: uri(event),
      message: @event_name_to_message[event_name]
    )
  end

  def render("grant_request_approval_addition.html", event),
    do: render_grant_request_approval(event)

  def render("grant_request_rejection.html", event), do: render_grant_request_approval(event)

  def render("grant_request_approval_consensus.html", event),
    do: render_grant_request_approval(event)

  def render("grant_request_status_process_start.html", event),
    do: render_grant_request_status(event)

  def render("grant_request_status_process_end.html", event),
    do: render_grant_request_status(event)

  def render("grant_request_status_cancellation.html", event),
    do: render_grant_request_status(event)

  def render("grant_request_status_failure.html", event), do: render_grant_request_status(event)

  def render("job_status_started.html", event), do: render_sources(event)
  def render("job_status_pending.html", event), do: render_sources(event)
  def render("job_status_failed.html", event), do: render_sources(event)
  def render("job_status_succeeded.html", event), do: render_sources(event)
  def render("job_status_warning.html", event), do: render_sources(event)
  def render("job_status_info.html", event), do: render_sources(event)

  def render("quality_control_created.html", %{event: %{payload: payload} = event}) do
    render("quality_control.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      uri: uri(event),
      status: payload["status"]
    )
  end

  def render("quality_control_version_deleted.html", %{event: event}) do
    render("quality_control.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      uri: nil,
      status: nil
    )
  end

  def render("quality_control_version_draft_created.html", %{event: event}) do
    render("quality_control.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      uri: uri(event),
      status: nil
    )
  end

  def render("quality_control_version_status_updated.html", %{event: %{payload: payload} = event}) do
    render("quality_control_version_status_updated.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      status: payload["status"],
      uri: uri(event)
    )
  end

  def render("score_status_updated.html", %{event: %{payload: payload} = event}) do
    render("score_status_updated.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      status: payload["status"],
      date: TdAudit.Helpers.shift_zone(payload["execution_timestamp"]),
      uri: uri(event),
      message: payload["message"],
      values: score_result_values(payload)
    )
  end

  def render(template, %{event: event}) do
    Logger.warning("Template #{template} not supported")

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

  defp render_implementation(%{event: %{payload: %{"status" => status}} = event}) do
    render("implementation_status_changed.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      status: status,
      uri: uri(event)
    )
  end

  defp render_tag(%{event: event}) do
    render("tag.html",
      event_name: event_name(event),
      user: user_name(event),
      name: EventView.resource_name(event),
      tag: resource_tag(event),
      comment: comment(event),
      domains: domain_path(event),
      uri: uri(event)
    )
  end

  defp render_notes(%{event: event}) do
    render("notes.html",
      event_name: event_name(event),
      name: EventView.resource_name(event),
      domains: domain_path(event),
      uri: uri(event),
      updated_children: Map.get(event, :updated_children, [])
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

  defp render_grant_approval(%{event: %{payload: payload} = event}) do
    render("grant_approvals.html",
      user: user_name(event),
      name: EventView.resource_name(event),
      uri: uri(event),
      status: payload["status"],
      comment: payload["comment"]
    )
  end

  defp render_grant_request_approval(%{event: %{event: event_name, payload: payload} = event}) do
    render("grant_request_approval.html",
      user: user_name(event),
      message: @event_name_to_message[event_name],
      name: EventView.resource_name(event),
      uri: uri(event),
      status: payload["status"],
      comment: payload["comment"]
    )
  end

  defp render_grant_request_status(%{event: %{event: event_name, payload: payload} = event}) do
    render("grant_request_status.html",
      user: user_name(event),
      message: @event_name_to_message[event_name],
      name: EventView.resource_name(event),
      uri: uri(event),
      status: payload["status"],
      comment: payload["comment"]
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

  defp format_number(%{} = payload, key), do: Map.get(payload, key)

  defp format_number(nil, _), do: nil

  defp format_number(value, "percentage") do
    Number.Percentage.number_to_percentage(value)
  end

  defp format_number(value, _format) do
    Number.Delimit.number_to_delimited(value)
  end

  defp user_name(%{user_id: 0}), do: "system"
  defp user_name(%{user: %{full_name: full_name}}), do: full_name
  defp user_name(_), do: nil

  defp domain_path(%{payload: %{"current_domains_ids" => current_domains_ids}}) do
    current_domains_ids
    |> Map.values()
    |> Enum.map(&build_domain_path/1)
  end

  defp domain_path(%{payload: %{"domain_ids" => domain_ids}}) do
    build_domain_path(domain_ids)
  end

  defp domain_path(%{resource_id: resource_id, resource_type: "concept"}) do
    case TdCache.ConceptCache.get(resource_id, :domain_ids) do
      {:ok, [_ | _] = domain_ids} -> build_domain_path(domain_ids)
      _ -> nil
    end
  end

  defp domain_path(_), do: nil

  defp build_domain_path(domain_ids) do
    domain_ids
    |> Enum.reverse()
    |> Enum.map(&TdCache.TaxonomyCache.get_domain/1)
    |> Enum.filter(& &1)
    |> Enum.map_join(" › ", & &1.name)
  end

  defp uri(event) do
    "#{host_name()}#{EventView.path(event)}"
  end

  defp target_uri(%{payload: %{"target_id" => id, "target_type" => "data_structure"}}) do
    "#{host_name()}/structures/#{id}"
  end

  defp target_uri(_), do: nil

  defp host_name, do: Application.fetch_env!(:td_audit, :host_name)

  defp event_name(%{event: "concept_rejected"}), do: "Concept rejected"
  defp event_name(%{event: "concept_submitted"}), do: "Concept sent for approval"
  defp event_name(%{event: "concept_rejection_canceled"}), do: "Rejection canceled"
  defp event_name(%{event: "concept_deprecated"}), do: "Concept deprecated"
  defp event_name(%{event: "concept_published"}), do: "Concept published"
  defp event_name(%{event: "delete_concept_draft"}), do: "Draft deleted"
  defp event_name(%{event: "implementation_created"}), do: "Implementation created"
  defp event_name(%{event: "implementation_status_updated"}), do: "Implementation status updated"
  defp event_name(%{event: "new_concept_draft"}), do: "New concept draft"
  defp event_name(%{event: "relation_created"}), do: "Created relation"
  defp event_name(%{event: "relation_deleted"}), do: "Deleted relation"
  defp event_name(%{event: "remediation_created"}), do: "Remediation plan created"
  defp event_name(%{event: "update_concept_draft"}), do: "Concept draft updated"
  defp event_name(%{event: "relation_deprecated"}), do: "Relation deprecated"
  defp event_name(%{event: "structure_note_deleted"}), do: "Structure note deleted"
  defp event_name(%{event: "structure_note_deprecated"}), do: "Structure note deprecated"
  defp event_name(%{event: "structure_note_draft"}), do: "Structure note to draft"

  defp event_name(%{event: "structure_note_pending_approval"}),
    do: "Structure note pending approval"

  defp event_name(%{event: "structure_note_published"}), do: "Structure note published"
  defp event_name(%{event: "structure_note_rejected"}), do: "Structure note rejected"
  defp event_name(%{event: "structure_note_updated"}), do: "Structure note updated"
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

  defp event_name(%{event: "rule_created"}), do: "Rule created"

  defp event_name(%{event: "quality_control_created"}), do: "Quality control created"

  defp event_name(%{event: "quality_control_version_deleted"}),
    do: "Quality control version deleted"

  defp event_name(%{event: "quality_control_version_draft_created"}),
    do: "New quality control draft version"

  defp event_name(%{event: "quality_control_version_status_updated"}),
    do: "Quality control status updated"

  defp event_name(%{event: "score_status_updated"}), do: "New score result"

  defp translate("goal"), do: "Target"
  defp translate("minimum"), do: "Threshold"
  defp translate("maximum"), do: "Threshold"
  defp translate("records"), do: "Record Count"
  defp translate("errors"), do: "Error Count"
  defp translate("result"), do: "Result"
  defp translate("message"), do: "Message"
  defp translate("count"), do: "Record Count"
  defp translate("control_mode"), do: "Control Mode"
  defp translate("result_message"), do: "Result"
  defp translate("meets_goal"), do: "Meets goal"
  defp translate("under_goal"), do: "Under goal"
  defp translate("under_threshold"), do: "Under threshold"
  defp translate("deviation"), do: "Deviation"
  defp translate("percentage"), do: "Percentage"
  defp translate("error_count"), do: "Error Count"

  defp relation_side(%{payload: %{"target_id" => id, "target_type" => "data_structure"}}) do
    case TdCache.StructureCache.get(id) do
      {:ok, %{external_id: external_id}} -> external_id
      _ -> nil
    end
  end

  defp relation_side(_), do: nil

  defp resource_tag(%{payload: %{"tag" => tag}}), do: tag

  defp resource_tag(_), do: nil

  defp comment(%{payload: %{"comment" => comment}}), do: comment

  defp comment(_), do: nil

  defp grant_date(%{payload: %{"start_date" => start_date}}, "start_date"), do: start_date

  defp grant_date(%{payload: %{"end_date" => end_date}}, "end_date"), do: end_date

  defp score_result_values(%{
         "control_mode" => mode,
         "result" => %{} = result,
         "score_criteria" => %{} = score_criteria
       }) do
    result_values =
      result
      |> Map.merge(score_criteria)
      |> Map.take(["result", "result_message", "deviation", "count", "percentage", "error_count"])
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn
        {"result", count} when mode == "count" ->
          {translate(mode), Number.Delimit.number_to_delimited(count)}

        {"result", ratio} ->
          {translate(mode), Number.Percentage.number_to_percentage(ratio)}

        {"result_message", message} ->
          {translate("result_message"), translate(message)}

        {"count", %{"goal" => goal, "maximum" => maximum}} ->
          [
            {translate("goal"), Number.Delimit.number_to_delimited(goal)},
            {translate("maximum"), Number.Delimit.number_to_delimited(maximum)}
          ]

        {"error_count", %{"goal" => goal, "maximum" => maximum}} ->
          [
            {translate("goal"), Number.Delimit.number_to_delimited(goal)},
            {translate("maximum"), Number.Delimit.number_to_delimited(maximum)}
          ]

        {"deviation", %{"goal" => goal, "maximum" => maximum}} ->
          [
            {translate("goal"), Number.Delimit.number_to_delimited(goal)},
            {translate("maximum"), Number.Delimit.number_to_delimited(maximum)}
          ]

        {"percentage", %{"goal" => goal, "minimum" => minimum}} ->
          [
            {translate("goal"), Number.Delimit.number_to_delimited(goal)},
            {translate("minimum"), Number.Delimit.number_to_delimited(minimum)}
          ]
      end)
      |> List.flatten()

    [{translate("control_mode"), translate(mode)} | result_values]
  end

  defp score_result_values(_), do: []
end
