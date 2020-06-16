defmodule TdAudit.Repo.Migrations.ModifySettingsInConfigurationSystem do
  use Ecto.Migration

  import Ecto.Query

  alias TdAudit.Repo

  def change do
    from(c in "notifications_system_configuration")
    |> where([c], c.event == "create_concept_draft")
    |> select([c], %{id: c.id, settings: c.settings})
    |> Repo.all()
    |> Enum.map(&update_settings/1)
  end

  defp update_settings(%{settings: settings} = params) do
    generate_subscription = Map.get(settings, "generate_subscription")
    update_subscription(generate_subscription, params)
  end

  defp update_subscription(nil, _), do: :ok

  defp update_subscription(generate_subscription, %{id: id, settings: settings}) do
    case Map.get(generate_subscription, "target_event") do
      nil ->
        gs = Map.put(generate_subscription, "target_event", "comment_created")
        new_settings = Map.put(settings, "generate_subscription", gs)

        from(c in "notifications_system_configuration")
        |> update([c], set: [settings: ^new_settings])
        |> where([c], c.id == ^id)
        |> Repo.update_all([])

      _ ->
        :ok
    end
  end
end
