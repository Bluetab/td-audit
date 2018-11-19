defmodule TdAudit.Repo.Migrations.AddNotificationsConfiguration do
  use Ecto.Migration

  def change do
    create table(:notifications_system_configuration) do
      add :event, :string
      add :configuration, :map

      timestamps()
    end

    create unique_index(:notifications_system_configuration, [:event], name: :index_notifications_system_configuration_by_event)
  end
end
