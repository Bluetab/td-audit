defmodule TdAudit.Repo.Migrations.AddSubscriptionsTable do
  @moduledoc """
  Add new subscriptions table
  """
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :event, :string
      add :resource_id, :integer
      add :resource_type, :string
      add :user_email, :string
      add :periodicity, :string

      timestamps()
    end
  end
end
