defmodule TdAudit.Repo.Migrations.AddDefaultValueToLastConsumedEvent do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      modify :last_consumed_event, :utc_datetime, default: fragment("now()")
    end
  end
end
