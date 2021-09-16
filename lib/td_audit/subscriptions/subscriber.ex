defmodule TdAudit.Subscriptions.Subscriber do
  @moduledoc """
  Ecto Schema module for Subscribers.
  """
  import Ecto.Changeset

  use Ecto.Schema

  alias TdAudit.Subscriptions.Subscription

  schema "subscribers" do
    field(:type, :string)
    field(:identifier, :string)

    has_many(:subscriptions, Subscription)

    timestamps()
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = subscription, attrs) do
    subscription
    |> cast(attrs, [:type, :identifier])
    |> validate_required([:type, :identifier])
    |> validate_inclusion(:type, ["email", "user", "role", "taxonomy_role"])
    |> unique_constraint(:unique_subscriber, name: :subscribers_type_identifier_index)
  end
end
