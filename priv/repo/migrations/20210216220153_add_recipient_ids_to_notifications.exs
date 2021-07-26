defmodule TdAudit.Repo.Migrations.AddRecipientIdsToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add(:recipient_ids, {:array, :integer}, default: [])
    end

    create(index(:notifications, [:recipient_ids]))
  end
end
