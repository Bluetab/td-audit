defmodule TdAudit.NotificationDispatcher do
  alias TdAudit.Audit
  alias TdAudit.Subscriptions

  @user_cache Application.get_env(:td_audit, :user_cache)
  @business_concept_cache Application.get_env(:td_audit, :business_concept_cache)

  @moduledoc """
  This module will create and dispatch the notifications created
  since the last consumption
  """
  def dispatch_notification({:dispatch_on_comment_creation, event}) do
    subscription_filters = %{"event" => event, "resource_type" => "business_concept"}

    subscription_filters
    |> Subscriptions.list_subscriptions_by_filter()
    |> Enum.map(&parse_subscription_format(&1))
    |> Enum.map(&retrieve_events_to_notificate(&1))
    |> Enum.map(&create_notifications(&1, :comment_creation))
  end

  defp parse_subscription_format(subscription) do
    base_filter_map =
      subscription
      |> Map.take([:id, :last_consumed_event, :event, :user_email])
      |> build_filter_for_field(:last_consumed_event, :gt)

    payload_filter_map =
      subscription
      |> Map.take([:resource_id, :resource_type])
      |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)

    Map.new()
    |> Map.put(:payload, payload_filter_map)
    |> Map.merge(base_filter_map)
  end

  defp retrieve_events_to_notificate(filter_params) do
    list_events =
      filter_params
      |> Map.take([:ts, :event, :payload, :user_email])
      |> Audit.list_events_by_filter()

    {Map.take(filter_params, [:id, :user_email]), list_events}
  end

  defp build_filter_for_field(origin_source, :last_consumed_event = field, filter) do
    value = origin_source |> Map.get(field)
    new_filter = Map.new() |> Map.put(:value, value) |> Map.put(:filter, filter)
    Map.put(origin_source, :ts, new_filter)
  end

  defp create_notifications(
         {subscriptor, subscription_data} = _data,
         :comment_creation = notification_type
       ) do
    subscription_data
    |> Enum.map(&compose_notification(&1, subscriptor, notification_type))
    |> Enum.map(&send_notification(&1, :email))
  end

  defp compose_notification(
         %{payload: payload, user_id: user_id},
         %{user_email: user_email},
         :comment_creation
       ) do
    %{"content" => content, "resource_id" => resource_id} =
      payload
      |> Map.take(["content", "resource_id"])

    business_concept_name = @business_concept_cache.get_name(resource_id)
    user_name = user_id |> @user_cache.get_user() |> Map.get(:user_name)

    Map.new()
    |> Map.put("who", user_name)
    |> Map.put("from", user_email)
    |> Map.put("entity_name", business_concept_name)
    |> Map.put("content", content)
  end

  defp send_notification(_data, :email) do
    #TODO
  end
end
