defmodule TdAudit.Repo.Migrations.AddFieldLastConsumedEvent do
  @moduledoc """
  Module creating new migration for the addition of a new field
  in subscriptions table registering the last consumed event
  """
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :last_consumed_event, :utc_datetime
    end
  end
end
