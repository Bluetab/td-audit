defmodule TdAudit.Repo.Migrations.AlterEventsTimestamps do
  use Ecto.Migration

  def change do
    alter table("events") do
      modify(:ts, :utc_datetime_usec, from: :utc_datetime)
      modify(:inserted_at, :utc_datetime_usec, from: :utc_datetime)
      remove(:updated_at, :utc_datetime)
    end

    alter table("subscriptions") do
      modify(:last_consumed_event, :utc_datetime_usec, from: :utc_datetime)
    end
  end
end
