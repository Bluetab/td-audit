defmodule TdAudit.Repo.Migrations.AlterSubscriptionsRemoveUserEmail do
  use Ecto.Migration

  def change do
    drop(
      unique_index(:subscriptions, [:event, :resource_id, :resource_type, :user_email],
        name: :unique_resource_subscription
      )
    )

    alter table("subscriptions") do
      remove(:user_email, :string)
    end

    create(
      unique_index(:subscriptions, [:event, :resource_id, :resource_type, :subscriber_id],
        name: :unique_resource_subscription
      )
    )
  end
end
