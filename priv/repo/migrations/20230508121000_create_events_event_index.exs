defmodule TdAudit.Repo.Migrations.CreateEventsEventIndex do
  use Ecto.Migration

  def change do
    create index("events", [:event])
  end
end
