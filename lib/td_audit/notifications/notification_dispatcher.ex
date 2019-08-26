defmodule TdAudit.NotificationDispatcher do
  alias TdAudit.Audit
  alias TdAudit.EmailBuilder
  alias TdAudit.Notifications.Messages
  alias TdAudit.Smtp.Mailer
  alias TdAudit.Subscriptions
  alias TdCache.ConceptCache
  alias TdCache.RuleCache
  alias TdCache.RuleResultCache
  alias TdCache.UserCache

  @concepts_path Application.get_env(:td_audit, :concepts_path)
  @rules_path Application.get_env(:td_audit, :rules_path)
  @row_params [:business_concept_name, :implementation_key, :rule_name, :result, :minimum]

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
      |> retrieve_events_with_subscribers()

    events_with_subscribers |> update_last_consumed_events()

    events_with_subscribers
    |> Enum.map(&compose_notification(&1, :comment_creation))
    |> Enum.map(&send_notification(&1, :email_on_comment))
  end

  def dispatch_notification({:dispatch_on_failed_results, event}) do
    subscription_filters = %{"event" => event, "resource_type" => "business_concept"}
    subscriptions = Subscriptions.list_subscriptions_by_filter(subscription_filters)
    {:ok, failed_ids} = RuleResultCache.members_failed_ids()

    results =
      failed_ids
      |> rule_results()
      |> with_rule()
      |> with_concept()
      |> Enum.group_by(&Map.get(&1, :business_concept_id))

    emails =
      subscriptions
      |> create_content(results)
      |> Enum.map(&compose_notification(&1, :failed_rule_results))
      |> Enum.map(&send_notification(&1, :failed_rule_results))

    unless emails == [] do
      clean_cache(failed_ids)
    end

    emails
  end

  defp rule_results(failed_ids) do
    failed_ids
    |> Enum.map(fn id ->
      case RuleResultCache.get(id) do
        {:ok, result} -> result
        _ -> nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp with_rule(rule_results) do
    rule_results
    |> Enum.map(fn result ->
      rule_id = Map.get(result, :rule_id)

      case RuleCache.get(rule_id) do
        {:ok, rule} ->
          rule
          |> Map.put(:rule_name, Map.get(rule, :name))
          |> Map.delete(:name)
          |> Map.merge(result)

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp with_concept(rule_results) do
    Enum.map(rule_results, fn result ->
      business_concept_id = Map.get(result, :business_concept_id)

      case ConceptCache.get(business_concept_id) do
        {:ok, concept} ->
          concept
          |> Map.put(:business_concept_name, Map.get(concept, :name))
          |> Map.delete(:name)
          |> Map.merge(result)

        _ ->
          nil
      end
    end)
  end

  defp create_content(subscriptions, results) do
    subscriptions
    |> Enum.group_by(&Map.get(&1, :user_email))
    |> Enum.map(fn {k, vs} -> {k, Enum.map(vs, &Map.get(&1, :resource_id))} end)
    |> Enum.map(fn {k, vs} -> {k, Enum.map(vs, &Map.get(results, Integer.to_string(&1)))} end)
    |> Enum.map(fn {k, vs} -> {k, Enum.filter(vs, & &1)} end)
    |> Enum.map(fn {k, vs} -> {k, List.flatten(vs)} end)
    |> Enum.filter(fn {_k, vs} -> not (vs == []) end)
  end

  defp clean_cache(failed_ids) do
    Enum.map(failed_ids, &RuleResultCache.delete_from_failed_ids/1)
  end

  defp update_last_consumed_events(events_with_subscribers) do
    events_with_subscribers
    |> Enum.map(&update_subscriber_last_consumed_event(&1))
  end

  defp update_subscriber_last_consumed_event(%{payload: payload, subscribers: subscribers, ts: ts}) do
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

  defp retrieve_events_to_notify(filter_params, acc) do
    list_events =
      filter_params
      |> Map.take([:ts, :event, :payload, :user_email])
      |> Audit.list_events_by_filter()
      |> Enum.map(&Map.put(&1, :subscribers, Map.get(filter_params, :user_email)))

    acc ++ list_events
  end

  defp group_events_and_subscribers({_key, [head | _tail] = events}) do
    head
    |> Map.take([:ts, :payload, :user_id])
    |> Map.put(:subscribers, events |> Enum.map(& &1.subscribers) |> Enum.uniq())
  end

  defp retrieve_events_with_subscribers(active_subscriptions_list) do
    active_subscriptions_list
    |> Enum.map(&parse_subscription_format(&1))
    |> Enum.reduce([], &retrieve_events_to_notify(&1, &2))
    |> Enum.group_by(& &1.id)
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

    with(
      {:ok, %{name: business_concept_name, business_concept_version_id: business_concept_version}} <-
        ConceptCache.get(resource_id),
      {:ok, %{full_name: user_name}} <- UserCache.get(user_id)
    ) do
      web_host = Application.get_env(:td_audit, :host_name)

      Map.new()
      |> Map.put("who", user_name)
      |> Map.put("to", subscribers)
      |> Map.put("entity_name", business_concept_name)
      |> Map.put("content", content)
      |> Map.put("resource_link", web_host <> @concepts_path <> "/#{business_concept_version}")
    end
  end

  defp compose_notification({email, results}, :failed_rule_results) do
    Map.new()
    |> Map.put("to", email)
    |> Map.put("content", Enum.map(results, &content_row(&1)))
  end

  defp content_row(row) do
    web_host = Application.get_env(:td_audit, :host_name)

    row
    |> Map.take(@row_params)
    |> Map.put(
      :concept_link,
      web_host <> @concepts_path <> "/#{Map.get(row, :business_concept_version_id)}"
    )
    |> Map.put(:rule_link, web_host <> @rules_path <> "/#{Map.get(row, :rule_id)}")
  end

  defp send_notification(%{"to" => to} = data, :email_on_comment) do
    %{subject: subject, body: body} = Messages.content_on_comment_creation(data)

    email = EmailBuilder.create(to, subject, body)
    email |> Mailer.deliver_now()
  end

  defp send_notification(%{"to" => to} = data, :failed_rule_results) do
    %{subject: subject, body: body} = Messages.content_on_failed_rule_results(data)

    email = EmailBuilder.create(to, subject, body)
    email |> Mailer.deliver_now()
  end
end
