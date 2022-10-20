defmodule TdAudit.Repo.Migrations.CreateEventsResourceIndex do
  use Ecto.Migration

  def change do
    create index("events", [:resource_type, :resource_id])
  end
end
