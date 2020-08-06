defmodule TdAudit.Subscriptions.Subscribers do
  @moduledoc """
  The Subscribers context.
  """
  import Ecto.Query

  alias TdAudit.Repo
  alias TdAudit.Subscriptions.Subscriber

  def list_subscribers do
    Repo.all(Subscriber)
  end

  def get_subscriber!(id) do
    Repo.get!(Subscriber, id)
  end

  def get_or_create_subscriber(subscriber_params) do
    case get_subscriber(subscriber_params) do
      nil ->
        create_subscriber(subscriber_params)
      subscriber ->
        {:ok, subscriber}
    end
  end

  def get_subscriber(%{"type" => type, "identifier" => identifier}) do
    Subscriber
      |> where([s], s.identifier == ^identifier)
      |> where([s], s.type == ^type)
      |> Repo.one()
  end

  def get_subscriber_by_user(user_id) do
    get_subscriber(%{"type" => "user", "identifier" => "#{user_id}"})
  end

  def create_subscriber(%{} = params) do
    params
    |> Subscriber.changeset()
    |> Repo.insert()
  end

  def delete_subscriber(%Subscriber{} = subscriber) do
    Repo.delete(subscriber)
  end
end
