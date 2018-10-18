defmodule TdAudit.Repo.Migrations.ChangeDqEvents do
  use Ecto.Migration

  def up do
    execute("update events set event='create_rule' where event='create_quality_control'")
    execute("update events set event='delete_rule' where event='delete_quality_control'")
    execute("update events set resource_type='rule' where resource_type='quality_control'")
  end

  def down do
    execute("update events set event='create_quality_control' where event='create_rule'")
    execute("update events set event='delete_quality_control' where event='delete_rule'")
    execute("update events set resource_type='quality_control' where resource_type='rule'")
  end


end
