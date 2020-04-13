defmodule TdAudit.Subscriptions do
  @moduledoc """
  The Audit context.
  """

  import Ecto.Query, warn: false

  alias TdAudit.NotificationsSystem.Configuration
  alias TdAudit.QuerySupport
  alias TdAudit.Repo
  alias TdAudit.Subscriptions.Subscription
  alias TdCache.{ConceptCache, UserCache}

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

      iex> list_subscriptions_by_filter(%{filed: value})
      [%Subscription{}, ...]

  """
  def list_subscriptions_by_filter(params) do
    fields = Subscription.__schema__(:fields)
    dynamic = QuerySupport.filter(params, fields)

    Repo.all(
      from(p in Subscription,
        where: ^dynamic
      )
    )
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
  def get_subscription!(id), do: Repo.get!(Subscription, id)

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(%{field: value})
      {:ok, %Event{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(subscription, %{field: new_value})
      {:ok, %Event{}}

      iex> update_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  def update_last_consumed_events_on_activation(
        {:ok, %Configuration{settings: settings} = configuration}
      ) do
    if has_subscription_been_activated?(settings) do
      update_last_consumed_events_by_event_type(
        Map.get(configuration, :event),
        DateTime.utc_now()
      )
    end
  end

  def update_last_consumed_events_on_activation(_) do
  end

  defp has_subscription_been_activated?(%{"generate_notification" => notification_settings}) do
    has_active_notification_flag?(notification_settings)
  end

  defp has_subscription_been_activated?(_), do: false

  defp has_active_notification_flag?(%{"active" => true}), do: true
  defp has_active_notification_flag?(_), do: false

  def update_last_consumed_events(
        %{
          "resource_id" => resource_id,
          "resource_type" => resource_type,
          "subscribers" => subscribers
        },
        last_consumed_event
      ) do
    query =
      from(
        from(p in Subscription,
          update: [set: [last_consumed_event: ^last_consumed_event]],
          where:
            p.resource_id == ^resource_id and
              p.resource_type == ^resource_type and
              p.user_email in ^subscribers
        )
      )

    query |> Repo.update_all([])
  end

  def update_last_consumed_events_by_event_type(
        event,
        last_consumed_event
      ) do
    query =
      from(
        from(p in Subscription,
          update: [set: [last_consumed_event: ^last_consumed_event]],
          where: p.event == ^event
        )
      )

    query |> Repo.update_all([])
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

    query = from(p in Subscription, where: ^dynamic)
    query |> Repo.delete_all()
  end

  def create_subscriptions(%{
        "role" => role,
        "event" => event,
        "resource_type" => resource_type,
        "periodicity" => periodicity
      }) do
    Repo.transaction(fn ->
      role
      |> get_resource_ids_by_subscriber(resource_type)
      |> Enum.flat_map(&subscription_params(&1, resource_type, event))
      |> Enum.reject(&Repo.get_by(Subscription, &1))
      |> Enum.map(&Map.put(&1, :periodicity, periodicity))
      |> Enum.map(&Subscription.changeset/1)
      |> Enum.map(&Repo.insert!/1)
    end)
  rescue
    e in Ecto.InvalidChangesetError -> {:error, e.changeset}
  end

  defp get_resource_ids_by_subscriber(role, "business_concept" = _resource_type) do
    {:ok, ids} = ConceptCache.active_ids()

    ids
    |> Enum.flat_map(&subscribers_from_role(&1, role))
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.flat_map(fn {full_name, ids} ->
      case UserCache.get_by_name(full_name) do
        {:ok, %{email: email}} -> [{email, ids}]
        _ -> []
      end
    end)
  end

  defp subscription_params({email, resource_ids}, resource_type, event) do
    Enum.map(resource_ids, fn resource_id ->
      %{
        user_email: email,
        resource_type: resource_type,
        resource_id: resource_id,
        event: event
      }
    end)
  end

  defp subscribers_from_role(concept_id, role) do
    case ConceptCache.get(concept_id, :content) do
      {:ok, nil} ->
        []

      {:ok, content} ->
        case Map.get(content, role) do
          nil -> []
          full_name -> [{full_name, concept_id}]
        end
    end
  end
end
