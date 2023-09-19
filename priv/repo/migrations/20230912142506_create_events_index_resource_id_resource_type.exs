defmodule TdAudit.Repo.Migrations.CreateEventsIndexResourceIdResourceType do
  use Ecto.Migration

  def up do
    drop_if_exists(index("events", ["resource_type_resource_id"]))

    create index("events", [:resource_type, :resource_id],
             where: "resource_type IS NOT NULL AND resource_id IS NOT NULL"
           )

    create index("events", [:resource_id, :resource_type],
             where: "resource_id IS NOT NULL AND resource_type IS NOT NULL"
           )

    execute("REINDEX INDEX events_resource_type_resource_id_index;")
    execute("REINDEX INDEX events_resource_id_resource_type_index;")
  end

  def down do
    drop_if_exists(index("events", ["resource_type_resource_id"]))
    drop_if_exists(index("events", ["resource_id_resource_type"]))

    create index("events", [:resource_type, :resource_id])

    execute("REINDEX INDEX events_resource_type_resource_id_index;")
  end
end
