defmodule TdAudit.Factory do
  @moduledoc """
  Factory methods for tests
  """

  use ExMachina.Ecto, repo: TdAudit.Repo

  alias TdAudit.Audit.Event
  alias TdAudit.Notifications.Notification
  alias TdAudit.Notifications.NotificationsReadByRecipients
  alias TdAudit.Notifications.Status
  alias TdAudit.Subscriptions.Subscriber
  alias TdAudit.Subscriptions.Subscription
  alias TdCache.ConceptCache
  alias TdCache.DomainCache
  alias TdCache.RuleCache

  def notification_factory(attrs) do
    %Notification{
      subscription: build(:subscription),
      events: [build(:event)],
      status: [build(:status)]
    }
    |> merge_attributes(attrs)
  end

  def notifications_read_by_recipients_factory(attrs) do
    %NotificationsReadByRecipients{} |> merge_attributes(attrs)
  end

  def status_factory(attrs) do
    %Status{
      status: "pending"
    }
    |> merge_attributes(attrs)
  end

  def subscription_factory(attrs) do
    attrs = default_assoc(attrs, :subscriber_id, :subscriber)

    %Subscription{
      periodicity: "daily",
      last_event_id: 0,
      scope: build(:scope)
    }
    |> merge_attributes(attrs)
  end

  def concept_subscription_factory(attrs) do
    concept_id = Map.get(attrs, :resource_id, 42)
    concept = %{id: concept_id, name: "concept", business_concept_version_id: "4"}
    {:ok, _} = ConceptCache.put(concept)
    build(:subscription, scope: %{resource_type: "concept", resource_id: concept_id})
  end

  def domains_subscription_factory(attrs) do
    domain_id = Map.get(attrs, :resource_id, 42)
    domain = %{id: domain_id, name: "domain", updated_at: ~N[2021-01-26 14:41:14]}
    {:ok, _} = DomainCache.put(domain)
    build(:subscription, scope: %{resource_type: "domains", resource_id: domain_id})
  end

  def domain_subscription_factory(attrs) do
    domain_id = Map.get(attrs, :resource_id, 42)
    domain = %{id: domain_id, name: "domain", updated_at: ~N[2021-01-26 14:41:14]}
    {:ok, _} = DomainCache.put(domain)
    build(:subscription, scope: %{resource_type: "domain", resource_id: domain_id})
  end

  def rule_subscription_factory(attrs) do
    rule_id = Map.get(attrs, :resource_id, 42)
    rule = %{id: rule_id, name: "rule", updated_at: ~N[2021-01-26 14:41:14]}
    {:ok, _} = RuleCache.put(rule)
    build(:subscription, scope: %{resource_type: "rule", resource_id: rule_id})
  end

  def scope_factory do
    %TdAudit.Subscriptions.Scope{
      events: ["ingest_sent_for_approval"],
      resource_type: sequence(:scope_resource_type, ["domains", "domain", "concept", "ingest"]),
      resource_id: 62
    }
  end

  def event_factory(attrs) do
    payload = string_params_for(:payload, Map.take(attrs, [:event]))
    resource_type = resource_type(attrs)

    %Event{
      event: "some_event",
      payload: payload,
      resource_id: 42,
      resource_type: resource_type,
      service: "some service",
      ts: DateTime.utc_now(),
      user_id: 42,
      user_name: "some name"
    }
    |> merge_attributes(attrs)
  end

  def payload_factory(%{event: "comment_created"} = attrs) do
    %{
      content: "a comment",
      resource_type: "business_concept",
      resource_id: 1
    }
    |> merge_attributes(Map.delete(attrs, :event))
  end

  def payload_factory(%{event: "rule_result_created"} = attrs) do
    %{
      date: "2020-02-02T00:00:00Z",
      goal: 100,
      name: "rule_name",
      params: %{"foo" => "bar"},
      result: "70.00",
      minimum: 80,
      status: "error",
      rule_id: 28_280,
      result_type: "percentage",
      implementation_key: "ri123",
      implementation_id: 19_188,
      id: 123,
      business_concept_id: "62"
    }
    |> merge_attributes(Map.delete(attrs, :event))
  end

  def payload_factory(%{event: "ingest_sent_for_approval"} = attrs) do
    %{
      id: 123,
      name: "My ingest",
      ingest: %{"id" => 11_885, "domain_id" => 65},
      version: 1,
      domain_ids: [65, 4, 1]
    }
    |> merge_attributes(Map.delete(attrs, :event))
  end

  def payload_factory(%{} = attrs) do
    merge_attributes(%{}, Map.delete(attrs, :event))
  end

  defp resource_type(%{resource_tye: resource_type}), do: resource_type
  defp resource_type(%{event: "comment_created"}), do: "comment"
  defp resource_type(%{event: "rule_result_created"}), do: "rule_result"
  defp resource_type(%{event: "ingest_sent_for_approval"}), do: "ingest"
  defp resource_type(_), do: "some resource_type"

  def subscriber_factory do
    %Subscriber{
      type: "email",
      identifier: sequence(:subscriber_identifier, &"username_#{&1}@example.com")
    }
  end

  def domain_factory do
    %{
      id: System.unique_integer([:positive]),
      parent_id: nil,
      name: sequence("domain_name"),
      updated_at: DateTime.utc_now()
    }
  end

  def user_factory do
    %{
      id: System.unique_integer([:positive]),
      user_name: sequence("user_name"),
      email: sequence("user_email") <> "@example.com"
    }
  end

  def concept_factory do
    %{
      id: System.unique_integer([:positive]),
      name: sequence("concept_name")
    }
  end

  defp default_assoc(attrs, id_key, key) do
    if Enum.any?([key, id_key], &Map.has_key?(attrs, &1)) do
      attrs
    else
      Map.put(attrs, key, build(key))
    end
  end
end
