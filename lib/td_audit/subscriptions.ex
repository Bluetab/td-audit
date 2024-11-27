defmodule TdAudit.Subscriptions do
  @moduledoc """
  The Audit context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias TdAudit.Audit
  alias TdAudit.QuerySupport
  alias TdAudit.Repo
  alias TdAudit.Subscriptions.Scope
  alias TdAudit.Subscriptions.Subscription
  alias TdCache.AclCache
  alias TdCache.ConceptCache
  alias TdCache.TaxonomyCache

  @doc """
  Returns the list of subscriptions.

  ## Examples

      iex> list_subscriptions()
      [%Subscription{}, ...]

  """
  def list_subscriptions do
    Repo.all(Subscription)
  end

  @doc """
  Returns the list of subscriptions after filters are applied.

  ## Examples

      iex> list_subscriptions(%{field: value})
      [%Subscription{}, ...]

  """
  def list_subscriptions(clauses) do
    fields = Subscription.__schema__(:fields)
    dynamic = QuerySupport.filter(clauses, fields)

    Repo.all(from(p in Subscription, preload: :subscriber, where: ^dynamic))
  end

  @doc """
  Gets a single Subscription.

  Raises `Ecto.NoResultsError` if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(123)
      %Subscription{}

      iex> get_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subscription!(id) do
    Subscription
    |> Repo.get!(id)
    |> Repo.preload(:subscriber)
  end

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(subscriber, %{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(subscriber, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(subscriber, params) do
    last_event_id = Audit.max_event_id() || 0

    %Subscription{last_event_id: last_event_id}
    |> Subscription.changeset(params)
    |> Changeset.put_assoc(:subscriber, subscriber)
    |> Changeset.validate_required(:subscriber)
    |> Repo.insert()
    |> preload_subscriber()
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(subscription, %{field: value})
      {:ok, %Subscription{}}

      iex> update_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Subscription{} = subscription, attrs) do
    scope = Map.get(attrs, "scope", %{})
    scope_changeset = Scope.update_changeset(subscription.scope, scope)

    subscription
    |> Subscription.update_changeset(attrs)
    |> Changeset.put_change(:scope, scope_changeset)
    |> Repo.update()
    |> preload_subscriber()
  end

  defp preload_subscriber({:ok, subscription}), do: {:ok, Repo.preload(subscription, :subscriber)}
  defp preload_subscriber(error), do: error

  @doc """
  Deletes a Subscription.

  ## Examples

      iex> delete_subscription(subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  @doc """
  Deletes a group of subscriptions filtered by a group of params.

  ## Examples

      iex> delete_all_subscriptions(params)

  """
  def delete_all_subscriptions(params) do
    fields = Subscription.__schema__(:fields)
    dynamic = QuerySupport.filter(params, fields)

    from(p in Subscription, where: ^dynamic)
    |> Repo.delete_all()
  end

  def list_recipient_ids(%Subscription{subscriber: %{type: "user", identifier: sid}}, events) do
    [String.to_integer(sid)]
    |> put_recipients_into_events(events)
  end

  def list_recipient_ids(
        %Subscription{
          subscriber: %{type: type, identifier: role},
          scope: %{
            events: ["grant_request_group_creation"],
            resource_id: domain_id,
            resource_type: resource_type
          }
        },
        events
      )
      when resource_type in ~w(domain domains) and
             type in ~w(role taxonomy_role) do
    domain_ids =
      case type do
        "role" -> [domain_id]
        "taxonomy_role" -> TaxonomyCache.reachable_domain_ids(domain_id)
      end

    Enum.into(events, %{}, fn %{
                                id: event_id,
                                payload: %{
                                  "domain_ids" => event_domain_ids,
                                  "requests" => event_requests
                                }
                              } ->
      structure_ids =
        structures_in_subscription_domain(
          [event_domain_ids, event_requests],
          domain_ids
        )

      recipient_ids =
        TdCache.AclCache.get_acl_user_ids_by_resources_role(
          %{
            "domain" => domain_ids,
            "structure" => structure_ids
          },
          role
        )

      {event_id, recipient_ids}
    end)
  end

  def list_recipient_ids(
        %Subscription{
          subscriber: %{type: "taxonomy_role", identifier: role},
          scope: %{resource_type: "domains", resource_id: domain_id}
        },
        events
      )
      when is_integer(domain_id) do
    subscription_domain_ids = TaxonomyCache.reachable_domain_ids(domain_id)

    Enum.reduce(
      events,
      %{},
      fn %{id: id, payload: payload} = event, acc ->
        recipient_ids =
          MapSet.intersection(
            MapSet.new(payload["domain_ids"]),
            MapSet.new(subscription_domain_ids)
          )
          |> list_recipient_ids_by_domains_role(role)

        maybe_impacted_user(acc, id, recipient_ids, event)
      end
    )
  end

  def list_recipient_ids(
        %Subscription{
          subscriber: %{type: "role", identifier: role},
          scope: %{resource_type: type, resource_id: domain}
        },
        events
      )
      when type in ~w(domain domains) do
    domain
    |> list_recipient_ids_by_role(role)
    |> put_recipients_into_events(events)
  end

  def list_recipient_ids(
        %Subscription{
          subscriber: %{type: "role", identifier: role},
          scope: %{resource_type: "concept", resource_id: concept}
        },
        events
      ) do
    concept
    |> list_concept_domains()
    |> Enum.flat_map(&list_recipient_ids_by_role(&1, role))
    |> put_recipients_into_events(events)
  end

  def list_recipient_ids(
        %Subscription{
          subscriber: %{type: "role", identifier: role},
          scope: %{resource_type: "data_structure", domain_id: domain_id}
        },
        events
      )
      when is_integer(domain_id) do
    domain_id
    |> TaxonomyCache.reaching_domain_ids()
    |> Enum.flat_map(&list_recipient_ids_by_role(&1, role))
    |> put_recipients_into_events(events)
  end

  def list_recipient_ids(_subscription, _events) do
    []
  end

  def put_recipients_into_events(recipient_ids, events) do
    Enum.reduce(
      events,
      %{},
      fn event, acc ->
        maybe_impacted_user(acc, event.id, recipient_ids, event)
      end
    )
  end

  defp list_recipient_ids_by_domains_role(domains, role) do
    domains
    |> Enum.uniq()
    |> Enum.reduce(
      [],
      fn domain, acc ->
        Kernel.++(list_recipient_ids_by_role(domain, role), acc)
      end
    )
    |> Enum.uniq()
  end

  defp list_recipient_ids_by_role(domain_id, role) do
    AclCache.get_acl_role_users("domain", domain_id, role)
  end

  defp list_concept_domains(resource_id) do
    case ConceptCache.get(resource_id, :domain_ids) do
      {:ok, domains} when is_list(domains) -> domains
      _ -> []
    end
  end

  defp maybe_impacted_user(
         acc,
         index,
         _recipient_ids,
         %{event: "grant_created", payload: %{"user_id" => granted_user_id}}
       ) do
    Map.put(acc, index, [granted_user_id])
  end

  defp maybe_impacted_user(acc, index, recipient_ids, _event) do
    Map.put(acc, index, recipient_ids)
  end

  defp structures_in_subscription_domain(req_domains_requests, subscription_domain_ids) do
    req_domains_requests
    |> Enum.zip()
    |> Enum.filter(fn {req_domain_ids, _} ->
      req_domain_ids
      |> MapSet.new()
      |> MapSet.intersection(MapSet.new(subscription_domain_ids))
      |> MapSet.size()
      |> Kernel.>(0)
    end)
    |> Enum.reduce([], fn {_, %{"data_structure" => %{"id" => ds_id}}}, acc ->
      [ds_id | acc]
    end)
  end
end
