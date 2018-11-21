defmodule TdAudit.NotificationDispatcher do
  alias TdAudit.Audit
  alias TdAudit.EmailBuilder
  alias TdAudit.Notifications.Messages
  alias TdAudit.Smtp.Mailer
  alias TdAudit.Subscriptions

  @user_cache Application.get_env(:td_audit, :user_cache)
  @business_concept_cache Application.get_env(:td_audit, :business_concept_cache)

  @moduledoc """
  This module will create and dispatch the notifications created
  since the last consumption
  """
  def dispatch_notification({:dispatch_on_comment_creation, event}) do
    subscription_filters = %{"event" => event, "resource_type" => "business_concept"}

    subscriptions_list =
      subscription_filters
      |> Subscriptions.list_subscriptions_by_filter()

    events_with_subscribers =
      subscriptions_list
      |> retrieve_events_with_subscribers

    events_with_subscribers |> update_last_consumed_events()

    events_with_subscribers
      |> Enum.map(&compose_notification(&1, :comment_creation))
      |> Enum.map(&send_notification(&1, :email_on_comment))
  end

  defp update_last_consumed_events(events_with_subscribers) do
    events_with_subscribers
      |> Enum.map(&update_subscriber_last_consumed_event(&1))
  end

  defp update_subscriber_last_consumed_event(
    %{payload: payload, subscribers: subscribers, ts: ts}
    ) do
      filter_params =
        payload
          |> Map.take(["resource_id", "resource_type"])
          |> Map.put("subscribers", subscribers)

      Subscriptions.update_last_consumed_events(filter_params, ts)
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

  defp retrieve_events_to_notificate(filter_params, acc) do
    list_events =
      filter_params
      |> Map.take([:ts, :event, :payload, :user_email])
      |> Audit.list_events_by_filter()
      |> Enum.map(&Map.put(&1, :subscribers, Map.get(filter_params, :user_email)))

    acc ++ list_events
  end

  defp group_events_and_subscribers({_key, [head|_tail] = events}) do
    head
      |> Map.take([:ts, :payload, :user_id])
      |> Map.put(:subscribers, events |> Enum.map(&(&1.subscribers)) |> Enum.uniq)
  end

  defp retrieve_events_with_subscribers(active_subscriptions_list) do
    active_subscriptions_list
        |> Enum.map(&parse_subscription_format(&1))
        |> Enum.reduce([], &retrieve_events_to_notificate(&1, &2))
        |> Enum.group_by(&(&1.id))
        |> Enum.map(&group_events_and_subscribers(&1))
        |> Enum.sort(&(Map.get(&1, :ts) <= Map.get(&2, :ts)))
  end

  defp build_filter_for_field(origin_source, :last_consumed_event = field, filter) do
    value = origin_source |> Map.get(field)
    new_filter = Map.new() |> Map.put(:value, value) |> Map.put(:filter, filter)
    Map.put(origin_source, :ts, new_filter)
  end

  defp compose_notification(
         %{payload: payload, user_id: user_id, subscribers: subscribers},
         :comment_creation
       ) do

    %{"content" => content, "resource_id" => resource_id} =
      payload
      |> Map.take(["content", "resource_id"])

    business_concept_name = @business_concept_cache.get_name(resource_id)
    user_name = user_id |> @user_cache.get_user() |> Map.get(:full_name)

    Map.new()
    |> Map.put("who", user_name)
    |> Map.put("to", subscribers)
    |> Map.put("entity_name", business_concept_name)
    |> Map.put("content", content)
  end

  defp send_notification(%{"to" => to} = data, :email_on_comment) do
    %{subject: subject, body: body} =
      Messages.content_on_comment_creation(data)

    email = EmailBuilder.create(to, subject, body)
    email |> Mailer.deliver_now
  end
end
