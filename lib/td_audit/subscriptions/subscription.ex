defmodule TdAudit.Subscriptions.Subscription do
  @moduledoc """
  Ecto Schema module for Subscriptions.
  """
  import Ecto.Changeset

  use Ecto.Schema

  schema "subscriptions" do
    field(:event, :string)
    field(:resource_id, :integer)
    field(:resource_type, :string)
    field(:user_email, :string)
    field(:periodicity, :string)
    field(:last_consumed_event, :utc_datetime_usec)

    timestamps()
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = subscription, attrs) do
    subscription
    |> cast(attrs, [
      :event,
      :resource_id,
      :resource_type,
      :periodicity,
      :user_email,
      :last_consumed_event
    ])
    |> validate_required([:resource_id, :resource_type, :event, :user_email])
    |> unique_constraint(:unique_resource_subscription, name: :unique_resource_subscription)
  end
end
