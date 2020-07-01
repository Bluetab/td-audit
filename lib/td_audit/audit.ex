defmodule TdAudit.Audit do
  @moduledoc """
  The Audit context.
  """

  import Ecto.Query

  alias TdAudit.Audit.Event
  alias TdAudit.QuerySupport
  alias TdAudit.Repo
  alias TdCache.UserCache

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events do
    user_map = UserCache.map()

    Event
    |> Repo.all()
    |> Enum.map(fn %{user_id: user_id} = e -> %{e | user: get_user(user_map, user_id)} end)
  end

  def list_events(params) do
    user_map = UserCache.map()

    fields = Event.__schema__(:fields)
    dynamic = QuerySupport.filter(params, fields)

    from(p in Event,
      where: ^dynamic,
      order_by: [desc: :ts]
    )
    |> Repo.all()
    |> Enum.map(fn %{user_id: user_id} = e -> %{e | user: get_user(user_map, user_id)} end)
  end

  def max_event_id do
    Event
    |> select([e], max(e.id))
    |> Repo.one()
  end

  defp get_user(user_map, id) do
    Map.get(user_map, id, %{id: id, full_name: "deleted", user_name: "deleted"})
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(params) do
    %Event{}
    |> Event.changeset(params)
    |> Repo.insert()
  end
end
