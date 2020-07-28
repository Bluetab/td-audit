defmodule TdAudit.Repo.Migrations.CascadeDeleteNotifications do
  use Ecto.Migration

  def up do
    drop(constraint("notifications", :notifications_subscription_id_fkey))
    drop(constraint("notification_status", :notification_status_notification_id_fkey))
    drop(constraint("notifications_events", :notifications_events_notification_id_fkey))

    alter table("notifications") do
      modify(:subscription_id, references("subscriptions", on_delete: :delete_all))
    end

    alter table("notification_status") do
      modify(:notification_id, references("notifications", on_delete: :delete_all))
    end

    alter table("notifications_events") do
      modify(:notification_id, references("notifications", on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint("notifications", :notifications_subscription_id_fkey))
    drop(constraint("notification_status", :notification_status_notification_id_fkey))
    drop(constraint("notifications_events", :notifications_events_notification_id_fkey))

    alter table("notifications") do
      modify(:subscription_id, references("subscriptions"))
    end

    alter table("notification_status") do
      modify(:notification_id, references("notifications"))
    end

    alter table("notifications_events") do
      modify(:notification_id, references("notifications"))
    end
  end
end
