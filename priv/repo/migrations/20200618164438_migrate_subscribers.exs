defmodule TdAudit.Repo.Migrations.MigrateSubscribers do
  use Ecto.Migration

  import Ecto.Query

  alias TdAudit.Repo

  def up do
    ts = DateTime.utc_now()

    from("subscriptions")
    |> select([s], s.user_email)
    |> distinct(true)
    |> Repo.all()
    |> Enum.map(&subscriber_entry(&1, ts))
    |> insert_subscribers()
    |> update_subscriptions()
  end

  def down do
    from("subscriptions")
    |> join(:inner, [s], c in "subscribers", on: c.id == s.subscriber_id)
    |> update([s, c], set: [user_email: c.identifier])
    |> Repo.update_all([])

    Repo.update_all("subscriptions", set: [subscriber_id: nil])
    Repo.delete_all("subscribers")
  end

  defp subscriber_entry(email, ts) do
    [type: "email", identifier: email, inserted_at: ts, updated_at: ts]
  end

  defp insert_subscribers(entries) do
    Repo.insert_all("subscribers", entries, returning: [:id, :identifier])
  end

  defp update_subscriptions({_count, inserted}) do
    Enum.map(inserted, fn %{id: id, identifier: user_email} ->
      from("subscriptions")
      |> where(user_email: ^user_email)
      |> update(set: [subscriber_id: ^id])
      |> Repo.update_all([])
    end)
  end
end
