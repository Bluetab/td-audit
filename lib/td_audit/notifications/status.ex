defmodule TdAudit.Notifications.Status do
  @moduledoc """
  Ecto Schema module for Notification status.
  """
  import Ecto.Changeset

  use Ecto.Schema

  alias Ecto.Changeset
  alias TdAudit.Notifications.Notification

  schema "notification_status" do
    field(:status, :string)
    belongs_to(:notification, Notification)

    timestamps(updated_at: false, type: :utc_datetime_usec)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = subscription, params) do
    subscription
    |> cast(params, [:notification_id, :status])
    |> cast_notification()
  end

  defp cast_notification(%Changeset{} = changeset) do
    case Changeset.get_field(changeset, :notification_id) do
      nil -> cast_assoc(changeset, :notification, with: &Notification.changeset/2, required: true)
      _id -> validate_required(changeset, :notification_id)
    end
  end
end
