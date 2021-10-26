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
  alias TdCache.{AclCache, ConceptCache, TaxonomyCache}

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
    |> Changeset.validate_required([:subscriber])
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

  def list_recipient_ids(%Subscription{
        subscriber: %{type: "taxonomy_role", identifier: role},
        scope: %{resource_type: type, resource_id: domain}
      }, events)
      when type == "domains" do

    subscription_domain_ids = TaxonomyCache.get_descendent_ids(domain)

    Enum.reduce(
      events,
      %{},
      fn event, acc ->
        Map.put(
          acc,
          event.id,
          MapSet.intersection(
            MapSet.new(event.payload["domain_ids"]),
            MapSet.new(subscription_domain_ids)
          )
          |> list_recipient_ids_by_domains_role(role)
        )
      end
    )
  end

  def list_recipient_ids(%Subscription{
        subscriber: %{type: "role", identifier: role},
        scope: %{resource_type: type, resource_id: domain}
      }, events)
      when type in ~w(domain domains) do

    list_recipient_ids_by_role(domain, role)
    |> put_recipients_into_events(events)
  end

  def list_recipient_ids(%Subscription{
        subscriber: %{type: "role", identifier: role},
        scope: %{resource_type: "concept", resource_id: concept}
      }, events) do

    concept
    |> list_concept_domains()
    |> Enum.flat_map(&list_recipient_ids_by_role(&1, role))
    |> put_recipients_into_events(events)
  end

  def list_recipient_ids(%Subscription{
        subscriber: %{type: "role", identifier: role},
        scope: %{resource_type: "data_structure", domain_id: id}
      }, events) do

    id
    |> TaxonomyCache.get_parent_ids()
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
        Map.put(acc, event.id, recipient_ids)
      end
    )
  end

  defp list_recipient_ids_by_domains_role(domains, role) do
    Enum.reduce(
      domains,
      [],
      fn domain, acc ->
        Kernel.++(list_recipient_ids_by_role(domain, role), acc)
      end
    )
  end

  defp list_recipient_ids_by_role(domain, role) do
    "domain"
    |> AclCache.get_acl_role_users(domain, role)
    |> Enum.map(&String.to_integer/1)
  end

  defp list_concept_domains(resource_id) do
    case ConceptCache.get(resource_id, :domain_ids) do
      {:ok, domains} when is_list(domains) -> domains
      _ -> []
    end
  end
end
