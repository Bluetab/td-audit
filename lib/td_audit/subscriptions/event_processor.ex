defmodule TdAudit.Subscriptions.EventProcessor do
  @moduledoc false

  alias TdAudit.NotificationsSystem
  alias TdAudit.NotificationsSystem.Configuration
  alias TdAudit.Subscriptions
  alias TdCache.UserCache

  require Logger

  def process_event(%{event: "create_concept_draft"} = event) do
    configurations =
      Map.new()
      |> Map.put("event", "create_concept_draft")
      |> NotificationsSystem.get_configurations_by_filter()

    process_event(configurations, event)
  end

  def process_event(%{event: "update_concept_draft", resource_id: resource_id} = event) do
    configurations =
      NotificationsSystem.get_configurations_by_filter(%{"event" => "create_concept_draft"})

    events =
      configurations
      |> Enum.filter(&changed_involved_roles?(&1, event))
      |> Enum.map(&target_event(&1))

    delete_subscriptions(%{
      "resource_id" => resource_id,
      "resource_type" => "business_concept",
      "event" => events
    })

    process_event(configurations, event)
  end

  def process_event(%{event: "delete_concept_draft", resource_id: resource_id}) do
    delete_subscriptions(%{"resource_type" => "business_concept", "resource_id" => resource_id})
  end

  def process_event(%{event: event}) do
    Logger.debug("Nothing defined for event '#{event}'")
  end

  defp process_event([], _event) do
    Logger.debug("No subscription config found")
  end

  defp process_event(configurations, event) when is_list(configurations) do
    Enum.map(configurations, &process_event_for_configuration(&1, event))
  end

  defp process_event_for_configuration(
         configuration,
         %{resource_id: resource_id, payload: payload}
       ) do
    involved_roles = involved_roles(configuration)
    target_event = target_event(configuration)

    params = %{
      "payload" => payload,
      "resource_id" => resource_id,
      "resource_type" => "business_concept",
      "target_event" => target_event
    }

    create_subscription_for_roles(params, involved_roles)
  end

  defp changed_involved_roles?(configuration, %{payload: %{"content" => %{"changed" => changed}}}) do
    roles = involved_roles(configuration)

    changed
    |> Map.keys()
    |> Enum.any?(&(&1 in roles))
  end

  defp changed_involved_roles?(_configuration, _event), do: false

  defp involved_roles(%Configuration{settings: settings}) do
    settings
    |> Map.fetch!("generate_subscription")
    |> Map.fetch!("roles")
  end

  defp target_event(%Configuration{settings: settings}) do
    settings
    |> Map.fetch!("generate_subscription")
    |> Map.get("target_event")
  end

  defp create_subscription_for_roles(
         %{
           "payload" => %{"content" => %{"changed" => content}},
           "resource_id" => resource_id,
           "resource_type" => resource_type,
           "target_event" => target_event
         },
         involved_roles
       ) do
    resource_id
    |> build_non_user_params(resource_type, target_event)
    |> create_subscription(involved_roles, content)
  end

  defp create_subscription_for_roles(
         %{
           "payload" => %{"content" => content},
           "resource_id" => resource_id,
           "resource_type" => resource_type,
           "target_event" => target_event
         },
         involved_roles
       ) do
    resource_id
    |> build_non_user_params(resource_type, target_event)
    |> create_subscription(involved_roles, content)
  end

  defp build_non_user_params(resource_id, resource_type, target_event) do
    %{}
    |> Map.put("resource_id", resource_id)
    |> Map.put("resource_type", resource_type)
    |> Map.put("event", target_event || "comment_created")
  end

  defp create_subscription(non_user_params, involved_roles, content) do
    involved_roles
    |> Enum.map(&Map.get(content, &1))
    |> Enum.filter(&(&1 != nil && is_binary(&1)))
    |> Enum.map(&UserCache.get_by_name!/1)
    |> Enum.map(&Map.get(&1, :email))
    |> Enum.filter(& &1)
    |> Enum.map(&Map.put(%{}, "user_email", &1))
    |> Enum.map(&Map.merge(&1, non_user_params))
    |> Enum.map(&Subscriptions.create_subscription/1)
  end

  defp delete_subscriptions(params) do
    Subscriptions.delete_all_subscriptions(params)
  end
end
