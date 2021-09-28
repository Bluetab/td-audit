defmodule TdAudit.Repo.Migrations.NotificationsReadByRecipients do
  use Ecto.Migration

  def change do
    create table(:notifications_read_by_recipients) do
      add(:notification_id, references(:notifications, on_delete: :delete_all))
      add(:recipient_id, :integer)
      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create(
      unique_index(
        :notifications_read_by_recipients,
        [:notification_id, :recipient_id],
        name: :notifications_read_unique_index
      )
    )
  end
end
