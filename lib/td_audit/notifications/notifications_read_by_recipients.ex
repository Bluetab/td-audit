defmodule TdAudit.Notifications.NotificationsReadByRecipients do
  @moduledoc """
  Ecto Schema module for Notifications.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias TdAudit.Audit.Event
  alias TdAudit.Notifications.Notification

  schema "notifications_read_by_recipients" do
    belongs_to(:notification, Notification)
    belongs_to(:event, Event)
    field(:recipient_id, :integer)

    timestamps(updated_at: false, type: :utc_datetime_usec)
  end

  def changeset(notification, recipient_id) do
    %__MODULE__{}
    |> cast(%{recipient_id: recipient_id}, [:recipient_id])
    |> put_assoc(:notification, notification)
    |> validate_required([:recipient_id])
    |> unique_constraint([:notification_id, :recipient_id])
  end
end
