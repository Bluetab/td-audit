defmodule TdAudit.Notifications.Notification do
  @moduledoc """
  Ecto Schema module for Notifications.
  """
  import Ecto.Changeset

  use Ecto.Schema

  alias TdAudit.Audit.Event
  alias TdAudit.Notifications.Status
  alias TdAudit.Subscriptions.Subscription

  schema "notifications" do
    belongs_to(:subscription, Subscription)
    many_to_many(:events, Event, join_through: "notifications_events")
    has_many(:status, Status)

    field(:recipient_ids, {:array, :integer}, default: [])

    timestamps(updated_at: false, type: :utc_datetime_usec)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = subscription, params) do
    subscription
    |> cast(params, [:subscription_id, :recipient_ids])
    |> validate_required([:recipient_ids])
  end
end
