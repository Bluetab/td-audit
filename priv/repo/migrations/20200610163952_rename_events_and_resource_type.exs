defmodule TdAudit.Repo.Migrations.RenameEventsAndResourceType do
  use Ecto.Migration

  def change do
    execute(
      "UPDATE events SET resource_type = 'concept' WHERE resource_type = 'business_concept' AND service = 'td_lm'",
      "UPDATE events SET resource_type = 'business_concept' WHERE resource_type = 'concept' AND service = 'td_lm'"
    )

    execute(
      "UPDATE events SET event = 'relation_created' WHERE event = 'add_relation'",
      "UPDATE events SET event = 'add_relation' WHERE event = 'relation_created'"
    )

    execute(
      "UPDATE events SET event = 'relation_deleted' WHERE event = 'delete_relation'",
      "UPDATE events SET event = 'delete_relation' WHERE event = 'relation_deleted'"
    )

    execute(
      "UPDATE events SET event = 'concept_submitted' WHERE event = 'concept_sent_for_approval'",
      "UPDATE events SET event = 'concept_sent_for_approval' WHERE event = 'concept_submitted'"
    )
  end
end
