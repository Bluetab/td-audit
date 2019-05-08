defmodule TdAudit.Repo.Migrations.TruncateTimestamps do
  use Ecto.Migration

  def up do
    execute("update events set ts=date_trunc('milliseconds', ts);")

    execute(
      "update subscriptions set last_consumed_event=date_trunc('milliseconds', last_consumed_event);"
    )
  end

  def down do
  end
end
