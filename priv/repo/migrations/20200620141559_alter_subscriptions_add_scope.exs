defmodule TdAudit.Repo.Migrations.AlterSubscriptionsAddScope do
  use Ecto.Migration

  def change do
    alter table("subscriptions") do
      add(:scope, :map)
    end
  end
end
