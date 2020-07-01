defmodule TdAudit.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table("notifications") do
      add(:subscription_id, references("subscriptions"))
      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create table("notification_status") do
      add(:notification_id, references("notifications"), on_delete: :delete_all)
      add(:status, :string, null: false)
      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create table("notifications_events", primary_key: false) do
      add(:notification_id, references("notifications"), on_delete: :delete_all)
      add(:event_id, references("events"), on_delete: :delete_all)
    end
  end
end
