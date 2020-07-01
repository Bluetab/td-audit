defmodule TdAudit.Repo.Migrations.AlterSubscriptionsRemoveResourceTypeId do
  use Ecto.Migration

  def change do
    drop(
      unique_index(:subscriptions, [:event, :resource_id, :resource_type, :subscriber_id],
        name: :unique_resource_subscription
      )
    )

    alter table("subscriptions") do
      remove(:event, :string)
      remove(:resource_id, :integer)
      remove(:resource_type, :string)
    end

    create(unique_index(:subscriptions, [:scope, :subscriber_id]))
  end
end
