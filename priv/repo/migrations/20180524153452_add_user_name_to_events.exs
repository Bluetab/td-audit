defmodule TdAudit.Repo.Migrations.AddUserNameToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:user_name, :string)
    end
  end
end
