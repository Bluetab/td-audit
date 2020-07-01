defmodule TdAudit.Repo.Migrations.AlterSubscriptionsAddLastIdRemoveLastConsumedEvent do
  use Ecto.Migration

  def up do
    alter table("subscriptions") do
      add(:last_event_id, :bigint)
    end

    execute("""
    UPDATE subscriptions AS s
    SET last_event_id = (
      SELECT MAX(e.id) FROM events AS e WHERE e.ts <= s.last_consumed_event
    )
    """)

    alter table("subscriptions") do
      remove(:last_consumed_event)
    end
  end

  def down do
    alter table("subscriptions") do
      add(:last_consumed_event, :utc_datetime_usec)
    end

    execute("""
    UPDATE subscriptions AS s
    SET last_consumed_event = e.ts
    FROM events AS e
    WHERE e.id = s.last_event_id
    """)

    alter table("subscriptions") do
      remove(:last_event_id)
    end
  end
end
