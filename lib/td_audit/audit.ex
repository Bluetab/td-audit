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
    cursor_params = get_cursor_params(params)

    additional_filters = [:start_ts, :end_ts]
    fields = Event.__schema__(:fields) ++ additional_filters
    dynamic = QuerySupport.filter(params, fields)

    Event
    |> where(^dynamic)
    |> where_cursor(cursor_params)
    |> page_limit(cursor_params)
    |> order(cursor_params)
    |> Repo.all()
    |> Enum.map(fn %{user_id: user_id} = e -> %{e | user: get_user(user_map, user_id)} end)
  end

  def max_event_id do
    Event
    |> select([e], max(e.id))
    |> Repo.one()
  end

  defp get_user(_user_map, 0 = id) do
    %{id: id, full_name: "system", user_name: "system"}
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

  defp get_cursor_params(%{"cursor" => %{} = cursor}) do
    id = Map.get(cursor, "id")
    size = Map.get(cursor, "size")

    %{cursor: %{id: id, size: size}}
  end

  defp get_cursor_params(params), do: params

  defp where_cursor(query, %{cursor: %{id: id}}) when is_integer(id) do
    where(query, [e], e.id > ^id)
  end

  defp where_cursor(query, _), do: query

  defp page_limit(query, %{cursor: %{size: size}}) when is_integer(size) do
    limit(query, ^size)
  end

  defp page_limit(query, _), do: query

  defp order(query, cursor_params) do
    case Map.has_key?(cursor_params, :cursor) do
      true -> order_by(query, [e], asc: e.id)
      false -> order_by(query, [e], desc: e.ts)
    end
  end
end
