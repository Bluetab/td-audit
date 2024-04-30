defmodule TdAudit.Repo.Migrations.MatchFkIdColumns do
  use Ecto.Migration

  def up do
    alter table(:events) do
      modify(:user_id, :bigint)
      modify(:resource_id, :bigint)
    end

    alter table(:notifications_read_by_recipients) do
      modify(:recipient_id, :bigint)
    end
  end

  def down do
    alter table(:events) do
      modify(:user_id, :integer)
      modify(:resource_id, :integer)
    end

    alter table(:notifications_read_by_recipients) do
      modify(:recipient_id, :integer)
    end
  end
end
