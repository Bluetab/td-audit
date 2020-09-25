defmodule TdAudit.Subscriptions do
  @moduledoc """
  The Audit context.
  """

  import Ecto.Query, warn: false

  alias TdAudit.Audit
  alias TdAudit.QuerySupport
  alias TdAudit.Repo
  alias TdAudit.Subscriptions.Subscription
  alias TdCache.AclCache
  alias TdCache.UserCache

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

      iex> create_subscription(%{field: value})
      {:ok, %Event{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(params \\ %{}) do
    last_event_id = Audit.max_event_id() || 0

    params
    |> Map.put_new("last_event_id", last_event_id)
    |> Subscription.changeset()
    |> Repo.insert()
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
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

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

  def get_recipients(%Subscription{subscriber: subscriber, scope: scope}) do
    recipients(subscriber, scope)
  end

  defp recipients({:ok, %{} = user}), do: recipients(user)
  defp recipients(%{full_name: full_name, email: email}), do: [{full_name, email}]
  defp recipients(%{email: email}), do: [email]
  defp recipients(_), do: []

  defp recipients(%{type: "email", identifier: email}, _scope) do
    [email]
  end

  defp recipients(%{type: "user", identifier: user_id}, _scope) do
    user_id
    |> UserCache.get()
    |> recipients()
  end

  defp recipients(%{type: "role", identifier: role}, %{
         resource_type: resource_type,
         resource_id: domain_id
       })
       when resource_type in ["domain", "domains"] do
    recipients_by_role(domain_id, role)
  end

  defp recipients(_, _), do: []

  defp recipients_by_role(domain_id, role_name) do
    "domain"
    |> AclCache.get_acl_role_users(domain_id, role_name)
    |> Enum.map(&UserCache.get/1)
    |> Enum.flat_map(&recipients/1)
  end
end