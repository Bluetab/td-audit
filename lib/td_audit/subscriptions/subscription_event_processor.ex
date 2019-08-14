defmodule TdAudit.SubscriptionEventProcessor do
  @moduledoc false
  require Logger
  alias TdAudit.NotificationsSystem
  alias TdAudit.NotificationsSystem.Configuration
  alias TdAudit.Subscriptions
  alias TdCache.UserCache

  def process_event(%{"event" => "create_concept_draft"} = event_params) do
    configurations =
      Map.new()
      |> Map.put("event", "create_concept_draft")
      |> NotificationsSystem.get_configurations_by_filter()

    process_event(configurations, event_params)
  end

  def process_event(%{"event" => "update_concept_draft"} = event_params) do
    configurations =
      Map.new()
      |> Map.put("event", "create_concept_draft")
      |> NotificationsSystem.get_configurations_by_filter()

    events = Enum.map(configurations, &target_event(&1))

    Map.new()
    |> Map.put("resource_id", Map.get(event_params, "resource_id"))
    |> Map.put("resource_type", "business_concept")
    |> Map.put("event", events)
    |> delete_subscriptions()

    process_event(configurations, event_params)
  end

  def process_event(%{"event" => "delete_concept_draft"} = event_params) do
    %{}
    |> Map.put("resource_type", "business_concept")
    |> Map.merge(Map.take(event_params, ["resource_id"]))
    |> delete_subscriptions()
  end

  def process_event(%{"event" => event, "resource_id" => resource_id}) do
    Logger.info(
      "SubscriptionEventProcessor not implemented for event #{event} and resource_id #{
        resource_id
      }"
    )
  end

  defp process_event([], _event_params) do
    Logger.info("No subscription configuration found for event create_concept_draft")
  end

  defp process_event(configurations, event_params) when is_list(configurations) do
    Enum.map(configurations, &process_event_for_configuration(&1, event_params))
  end

  defp process_event_for_configuration(configuration, event_params) do
    involved_roles = involved_roles(configuration)
    target_event = target_event(configuration)

    params =
      event_params
      |> Map.take(["payload", "resource_id"])
      |> Map.put("resource_type", "business_concept")
      |> Map.put("target_event", target_event)

    create_subscription_for_roles(
      params,
      involved_roles
    )
  end

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
    |> Map.put("event", target_event || "create_comment")
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
