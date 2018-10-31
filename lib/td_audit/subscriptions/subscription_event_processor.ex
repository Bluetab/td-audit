defmodule TdAudit.SubscriptionEventProcessor do
  @moduledoc false
  require Logger
  alias TdAudit.Subscriptions

  @custom_events Application.get_env(:td_audit, :custom_events)
  @user_cache Application.get_env(:td_audit, :user_cache)

  def process_event(%{"event" => "create_concept_draft"} = event_params) do
    involved_roles =
      @custom_events
      |> Enum.find(&(Map.fetch!(&1, :name) == "create_concept_draft"))
      |> Map.fetch!(:event_subscribers)

    create_subscription_for_role(
      Map.take(event_params, ["payload", "resource_id", "resource_type"]),
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
         "payload" => %{"content" => content},
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
      |> Enum.filter(&(&1 != nil && is_map(&1) && &1 != %{}))
      |> Enum.map(&@user_cache.get_user(Map.get(&1, "id")))
      |> Enum.map(&Map.get(&1, "email"))
      |> Enum.map(&Map.put(%{}, "user_email", &1))
      |> Enum.map(&Map.merge(&1, non_user_params))
      |> Enum.map(&Subscriptions.create_subscription(&1))
  end

  defp delete_subscriptions(params) do
    Subscriptions.delete_all_subscriptions(params)
  end
end
