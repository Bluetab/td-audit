defmodule TdAudit.Subscriptions.Subscribers do
  @moduledoc """
  The Subscribers context.
  """

  alias TdAudit.Repo
  alias TdAudit.Subscriptions.Subscriber

  def list_subscribers do
    Repo.all(Subscriber)
  end

  def get_subscriber!(id) do
    Repo.get!(Subscriber, id)
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
