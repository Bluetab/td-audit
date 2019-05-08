defmodule TdAudit.Subscriptions.Subscription do
  @moduledoc """
  Module defining the existing attributes for a
  Subscription entity
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "subscriptions" do
    field(:event, :string)
    field(:resource_id, :integer)
    field(:resource_type, :string)
    field(:user_email, :string)
    field(:periodicity, :string)
    field(:last_consumed_event, :utc_datetime_usec)

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event,
      :resource_id,
      :resource_type,
      :periodicity,
      :user_email,
      :last_consumed_event
    ])
    |> validate_required([:resource_id, :resource_type, :event, :user_email])
  end
end
