defmodule TdAudit.Repo.Migrations.CreateSubscribers do
  use Ecto.Migration

  def change do
    create table("subscribers") do
      add(:type, :string)
      add(:identifier, :string)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index("subscribers", [:type, :identifier]))

    alter table("subscriptions") do
      add(:subscriber_id, references("subscribers", on_delete: :delete_all))
    end
  end
end
