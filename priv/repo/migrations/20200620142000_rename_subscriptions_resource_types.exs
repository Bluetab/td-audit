defmodule TdAudit.Repo.Migrations.RenameSubscriptionsResourceTypes do
  use Ecto.Migration

  def change do
    execute(
      "update subscriptions set resource_type='concept' where resource_type='business_concept'",
      "update subscriptions set resource_type='business_concept' where resource_type='concept'"
    )
  end
end
