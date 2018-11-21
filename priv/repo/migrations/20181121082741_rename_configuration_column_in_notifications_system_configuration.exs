defmodule TdAudit.Repo.Migrations.RenameConfigurationColumnInNotificationsSystemConfiguration do
  @moduledoc """
  Renaming of the column configuration to settings
  """
  use Ecto.Migration

  def change do
    rename table(:notifications_system_configuration), :configuration, to: :settings
  end
end
