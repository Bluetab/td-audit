defmodule TdAudit.SubscriptionEventProcessor do
  @moduledoc false
  require Logger
  alias TdAudit.NotificationsSystem
  alias TdAudit.Subscriptions

  @user_cache Application.get_env(:td_audit, :user_cache)

  def process_event(%{"event" => "create_concept_draft"} = event_params) do
    involved_roles =
      Map.new()
      |> Map.put("event", "create_concept_draft")
      |> NotificationsSystem.get_configuration_by_filter!()
      |> Map.fetch!(:configuration)
      |> Map.fetch!("generate_subscription")
      |> Map.fetch!("roles")

    involved_params = event_params |> Map.take(["payload", "resource_id", "resource_type"])

    create_subscription_for_role(
      involved_params,
      involved_roles
    )
  end

  def process_event(%{"event" => "delete_concept_draft"}  = event_params) do
    %{}
    |> Map.put("event", "create_comment")
    |> Map.merge(Map.take(event_params, ["resource_id", "resource_type"]))
    |> delete_subscriptions()
  end

  def process_event(%{"event" => event, "resource_id" => resource_id}) do
    Logger.info(
      "SubscriptionEventProcessor not implemented for event #{event} and resource_id #{resource_id}"
    )
  end

  defp create_subscription_for_role(%{
         "payload" => %{"content" => content} = payload,
         "resource_id" => resource_id,
         "resource_type" => resource_type
       },
       involved_roles) do

    non_user_params =
      %{}
      |> Map.put("resource_id", resource_id)
      |> Map.put("resource_type", resource_type)
      |> Map.put("event", "create_comment")

    involved_roles
      |> Enum.map(&Map.get(content, &1))
      |> Enum.filter(&(&1 != nil && is_binary(&1)))
      |> Enum.map(&@user_cache.get_user_email(&1))
      |> Enum.filter(&(&1 != nil && is_binary(&1)))
      |> Enum.map(&Map.put(%{}, "user_email", &1))
      |> Enum.map(&Map.merge(&1, non_user_params))
      |> Enum.map(&Subscriptions.create_subscription(&1))
  end

  defp delete_subscriptions(params) do
    Subscriptions.delete_all_subscriptions(params)
  end
end
