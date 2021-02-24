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
      date: payload["date"],
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
end
