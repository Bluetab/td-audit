defmodule TdAudit.Subscriptions.Events do
  @moduledoc """
  The Subscription Events context
  """

  import Ecto.Query

  alias TdAudit.Audit.Event
  alias TdAudit.Repo
  alias TdAudit.Subscriptions.Subscription
  alias TdCache.TemplateCache
  alias TdDfLib.Format

  @doc """
  Returns a list of event identifiers matching the given subscription, with `id`
  less than or equal to the specified `max_id`.
  """
  def subscription_event_ids(%Subscription{last_event_id: prev_id, scope: scope}, max_id) do
    Event
    |> where([e], e.id > ^prev_id)
    |> where([e], e.id <= ^max_id)
    |> select([e], e.id)
    |> filter_by_scope(scope)
    |> Repo.all()
  end

  # filter for business glossary comments
  defp filter_by_scope(
         query,
         %{
           events: ["comment_created"],
           resource_type: "concept",
           resource_id: concept_id
         } = scope
       ) do
    resource_types = ["business_concept", "concept"]

    query
    |> where([e], e.event == "comment_created")
    |> where([e], fragment("? \\?& ?", e.payload, ["resource_type", "resource_id"]))
    |> where([e], e.payload["resource_type"] in ^resource_types)
    |> where([e], e.payload["resource_id"] == ^concept_id)
    |> where_content_condition(scope)
  end

  # filter for rule results
  defp filter_by_scope(
         query,
         %{
           events: ["rule_result_created"] = events,
           status: status,
           resource_type: "concept",
           resource_id: concept_id
         } = scope
       ) do
    concept_id = to_string(concept_id)

    query
    |> where([e], e.event in ^events)
    |> where([e], fragment("? \\?& ?", e.payload, ["status", "business_concept_id"]))
    |> where([e], e.payload["status"] in ^status)
    |> where([e], e.payload["business_concept_id"] == ^concept_id)
    |> where_content_condition(scope)
  end

  defp filter_by_scope(
         query,
         %{
           events: ["rule_result_created"] = events,
           status: status,
           resource_type: "rule",
           resource_id: rule_id
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], e.payload["status"] in ^status)
    |> where([e], e.payload["rule_id"] == ^rule_id)
    |> where_content_condition(scope)
  end

  # filter for concepts
  defp filter_by_scope(
         query,
         %{
           events: events,
           resource_type: "concept",
           resource_id: concept_id
         } = scope
       ) do
    resource_types = ["business_concept", "concept"]
    concept_id = to_string(concept_id)

    query
    |> where([e], e.event in ^events)
    |> where([e], e.resource_id == ^concept_id)
    |> where([e], e.resource_type in ^resource_types)
    |> where_content_condition(scope)
  end

  # filter for domain-scoped events, excluding subdomains
  defp filter_by_scope(
         query,
         %{events: events, resource_type: "domain", resource_id: resource_id} = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], fragment("? \\?& ?", e.payload, ["domain_ids"]))
    |> where([e], fragment("(? #>>'{domain_ids,0}')::integer = ?", e.payload, ^resource_id))
    |> where_content_condition(scope)
  end

  # filter for domain-scoped events, including subdomains
  defp filter_by_scope(
         query,
         %{
           events: events,
           resource_type: "domains",
           resource_id: resource_id
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], fragment("? \\?& ?", e.payload, ["domain_ids"]))
    |> where([e], fragment("? @> ?", e.payload["domain_ids"], ^resource_id))
    |> where_content_condition(scope)
  end

  defp filter_by_scope(
         query,
         %{
           events: events,
           resource_type: resource_type,
           resource_id: resource_id
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], e.resource_type == ^resource_type)
    |> where([e], e.resource_id == ^resource_id)
    |> where_content_condition(scope)
  end

  defp where_content_condition(query, %{
         filters: %{template: %{"id" => id}, content: %{} = content}
       }) do
    case TemplateCache.get(id) do
      {:ok, %{:content => content_schema}} ->
        do_build_content_condition(query, content_schema, content)

      _ ->
        query
    end
  end

  defp where_content_condition(query, _fiters), do: query

  defp do_build_content_condition(query, content_schema, %{"name" => name} = content) do
    content_schema
    |> Format.flatten_content_fields()
    |> Enum.find(fn %{"name" => field_name} -> field_name == name end)
    |> case do
      nil -> query
      field -> where_from_cardinality(query, content, Map.get(field, "cardinality"))
    end
  end

  defp do_build_content_condition(query, _template, _content), do: query

  defp where_from_cardinality(query, %{"name" => name, "value" => value}, cardinality)
       when cardinality in ["+", "*"] do
    where(
      query,
      [e],
      fragment("? @> ?", e.payload["subscribable_fields"], ~s({"#{name}":["#{value}"]}))
    )
  end

  defp where_from_cardinality(query, %{"name" => name, "value" => value}, _cardinality) do
    where(query, [e], fragment("? @> ?", e.payload["subscribable_fields"], ~s({"#{name}":"#{value}"})))
  end
end
