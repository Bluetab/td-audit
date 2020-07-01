defmodule TdAudit.Repo.Migrations.MigrateSubscriptionsScope do
  use Ecto.Migration

  import Ecto.Query

  alias TdAudit.Repo

  def up do
    from("subscriptions")
    |> select([:id, :event, :resource_type, :resource_id])
    |> Repo.all()
    |> Enum.map(&{&1.id, scope(&1)})
    |> Enum.map(fn {id, scope} ->
      from("subscriptions")
      |> where(id: ^id)
      |> update(set: [scope: ^scope])
      |> Repo.update_all([])
    end)
  end

  defp scope(%{
         event: "failed_rule_results",
         resource_type: resource_type,
         resource_id: resource_id
       }) do
    %{
      events: ["rule_result_created"],
      status: ["error"],
      resource_type: resource_type,
      resource_id: resource_id
    }
  end

  defp scope(%{event: event, resource_type: resource_type, resource_id: resource_id}) do
    %{
      events: [event],
      resource_type: resource_type,
      resource_id: resource_id
    }
  end

  def down do
    from("subscriptions")
    |> select([:id, :scope])
    |> Repo.all()
    |> Enum.map(fn %{id: id, scope: scope} ->
      %{"resource_type" => resource_type, "resource_id" => resource_id} = scope
      event = event(scope)

      from("subscriptions")
      |> where(id: ^id)
      |> update(set: [event: ^event, resource_type: ^resource_type, resource_id: ^resource_id])
      |> Repo.update_all([])
    end)
  end

  defp event(%{"events" => ["rule_result_created"]}), do: "failed_rule_results"
  defp event(%{"events" => [event | _]}), do: event
end
