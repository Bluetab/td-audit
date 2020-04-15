defmodule TdAudit.Repo.Migrations.CreateSubscriptionUniqueIndex do
  use Ecto.Migration

  def change do
    create(
      unique_index(:subscriptions, [:event, :resource_id, :resource_type, :user_email],
        name: :unique_resource_subscription
      )
    )
  end
end
