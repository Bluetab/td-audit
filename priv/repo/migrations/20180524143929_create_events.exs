defmodule TdAudit.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add(:service, :string)
      add(:resource_id, :integer)
      add(:resource_type, :string)
      add(:event, :string)
      add(:payload, :map)
      add(:user_id, :integer)
      add(:ts, :utc_datetime)

      timestamps()
    end
  end
end
