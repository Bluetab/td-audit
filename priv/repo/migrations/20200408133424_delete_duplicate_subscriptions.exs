defmodule TdAudit.Repo.Migrations.DeleteDuplicateSubscriptions do
  import Ecto.Query

  use Ecto.Migration

  alias TdAudit.Repo

  def up do
    from(s in "subscriptions")
    |> group_by([s], [s.event, s.resource_type, s.resource_id, s.user_email])
    |> having([s], count(s) > 1)
    |> select([g], {g.event, g.resource_type, g.resource_id, g.user_email})
    |> Repo.all()
    |> Enum.flat_map(&get_duplicate_ids/1)
    |> delete_subscriptions()
  end

  defp get_duplicate_ids({event, resource_type, resource_id, user_email}) do
    from(s in "subscriptions")
    |> where([s], s.event == ^event)
    |> where([s], s.resource_type == ^resource_type)
    |> where([s], s.resource_id == ^resource_id)
    |> where([s], s.user_email == ^user_email)
    |> order_by([s], desc: s.updated_at, asc: s.id)
    |> select([s], s.id)
    |> Repo.all()
    |> tl()
  end

  defp delete_subscriptions(ids) do
    from(s in "subscriptions")
    |> where([s], s.id in ^ids)
    |> select([s], s.id)
    |> Repo.delete_all()
  end

  def down do
    :ok
  end
end
