defmodule TdAudit.Repo.Migrations.DeleteUniqueIndexNotificationsConfiguration do
  use Ecto.Migration

  def change do
    drop_if_exists index(:notifications_system_configuration, [:event], name: :index_notifications_system_configuration_by_event)
  end
end
