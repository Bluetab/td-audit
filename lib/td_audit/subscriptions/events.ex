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

  def subscription_events(subscription, max_id) do
    subscription_events_query(subscription, max_id)
    |> Repo.all()
  end

  defp subscription_events_query(%Subscription{last_event_id: prev_id, scope: scope}, max_id) do
    Event
    |> where([e], e.id > ^prev_id)
    |> where([e], e.id <= ^max_id)
    |> filter_by_scope(scope)
  end

  # filter for implementation status updated
  defp filter_by_scope(
         query,
         %{
           events: ["implementation_status_updated"],
           resource_type: "domain",
           resource_id: resource_id
         } = scope
       ),
       do: filter_by_scope(query, %{scope | resource_type: "domains", resource_id: [resource_id]})

  defp filter_by_scope(
         query,
         %{
           events: ["implementation_status_updated"] = events,
           status: status,
           resource_type: "domains",
           resource_id: resource_id
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], fragment("? \\?& ?", e.payload, ["domain_ids"]))
    |> where([e], fragment("? @> ?", e.payload["domain_ids"], ^resource_id))
    |> where([e], e.payload["status"] in ^status)
    |> where_content_condition(scope)
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

  defp filter_by_scope(
         query,
         %{
           events: ["rule_result_created"] = events,
           status: status,
           resource_type: "implementation",
           resource_id: implementation_ref
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], e.payload["status"] in ^status)
    # rule_results event payload uses implementation_ref instead of ID.
    # to track multiple implementation versions.
    |> where([e], e.payload["implementation_ref"] == ^implementation_ref)
    |> where_content_condition(scope)
  end

  defp filter_by_scope(
         query,
         %{
           events: ["rule_result_created"] = events,
           status: status,
           resource_type: "domains",
           resource_id: resource_id
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], fragment("? \\?& ?", e.payload, ["domain_ids"]))
    |> where([e], fragment("? @> ?", e.payload["domain_ids"], ^resource_id))
    |> where([e], e.payload["status"] in ^status)
    |> where_content_condition(scope)
  end

  defp filter_by_scope(
         query,
         %{
           events: ["rule_result_created"] = events,
           status: status,
           resource_type: "domain",
           resource_id: resource_id
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], fragment("? \\?& ?", e.payload, ["domain_ids"]))
    |> where([e], fragment("(? #>>'{domain_ids,0}')::integer = ?", e.payload, ^resource_id))
    |> where([e], e.payload["status"] in ^status)
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

  defp filter_by_scope(
         query,
         %{
           events: ["grant_request_group_creation"] = events,
           resource_type: "domain",
           resource_id: resource_id
         } = scope
       ) do
    query
    |> join(:inner_lateral, [e], fragment("jsonb_array_elements(? -> 'domain_ids')", e.payload),
      as: :domain_ids,
      on: true
    )
    |> where([e], e.event in ^events)
    |> where([e], fragment("? \\?& ?", e.payload, ["domain_ids"]))
    # First element (->> 0) of the domain_ids list is the event resource_id
    # domain (might be different than scope resource_id), rest of elements
    # are ancestry.
    |> where([e, domain_ids], fragment("(? ->> 0)::int = ?", domain_ids, ^resource_id))
    |> where_content_condition(scope)
  end

  defp filter_by_scope(
         query,
         %{
           events: ["grant_request_group_creation"] = events,
           resource_type: "domains",
           resource_id: resource_id
         } = scope
       ) do
    query
    # Flatten payload domain_ids list of lists
    |> join(:inner_lateral, [e], fragment("jsonb_array_elements(? -> 'domain_ids')", e.payload),
      as: :domain_ids_arrays,
      on: true
    )
    |> join(
      :inner_lateral,
      [e, domain_ids_arrays],
      fragment("jsonb_array_elements(?)", domain_ids_arrays),
      as: :domain_ids_flattened,
      on: true
    )
    |> where([e], e.event in ^events)
    |> where([e], fragment("? \\?& ?", e.payload, ["domain_ids"]))
    |> where(
      [e, _domain_ids_arrays, domain_ids_flattened],
      fragment("?::int = ?", domain_ids_flattened, ^resource_id)
    )
    |> where_content_condition(scope)
    # Distinct in case resource_id is present in multiple ancestries (domain_ids_arrays)
    # jsonb_array_elements produces one column, named "value"
    # select all fields that are equal (events.* + domain_ids_flattened.value, exclude domain_ids_arrays)
    # domain_ids added to TdAudit.Audit.Event as virtual field
    |> select([e, _domain_ids_arrays, domain_ids_flattened], %{
      e
      | domain_ids: domain_ids_flattened.value
    })
    |> distinct(true)
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
           resource_type: "data_structure",
           resource_id: resource_id
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where(
      [e],
      (e.resource_id == ^resource_id and e.resource_type == "data_structure") or
        (e.resource_type == "data_structure_note" and
           fragment("? @> ?", e.payload["data_structure_id"], ^resource_id))
    )
    |> where_content_condition(scope)
  end

  defp filter_by_scope(
         query,
         %{
           status: events,
           resource_type: "source",
           resource_id: resource_id
         } = scope
       ) do
    query
    |> where([e], e.event in ^events)
    |> where([e], fragment("(?->>'source_id')::integer = ?", e.payload, ^resource_id))
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
    where(
      query,
      [e],
      fragment("? @> ?", e.payload["subscribable_fields"], ~s({"#{name}":"#{value}"}))
    )
  end
end
