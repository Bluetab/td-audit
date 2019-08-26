defmodule TdAudit.NotificationDispatcherTest do
  @moduledoc """
  Testing of the module TdAudit.NotificationDispatcher
  """
  use ExUnit.Case
  use TdAudit.DataCase

  alias TdAudit.Audit
  alias TdAudit.NotificationDispatcher
  alias TdAudit.Subscriptions
  alias TdCache.ConceptCache
  alias TdCache.RuleCache
  alias TdCache.RuleResultCache
  alias TdCache.UserCache

  describe "notification_dispatcher" do
    @user_1 %{
      "id" => 42,
      "user_name" => "my_user_name",
      "email" => "my_user_email@foo.bar",
      "full_name" => "My User Name"
    }
    @bc_1 %{
      "id" => 1,
      "domain_id" => 4,
      "name" => "BC Name 1",
      "business_concept_version_id" => 1
    }
    @bc_4 %{
      "id" => 4,
      "domain_id" => 4,
      "name" => "BC Name 4",
      "business_concept_version_id" => 1
    }
    @rule %{
      id: 1000,
      active: true,
      name: "Rule Name",
      updated_at: DateTime.utc_now(),
      business_concept_id: @bc_4["id"],
      minimum: 100
    }
    @resut_1 %{
      id: 1000,
      date: DateTime.utc_now(),
      implementation_key: "Key 1",
      result: 80,
      rule_id: @rule.id
    }
    @resut_2 %{
      id: 2000,
      date: DateTime.utc_now(),
      implementation_key: "Key 2",
      result: 75,
      rule_id: @rule.id
    }

    @user_list [@user_1]
    @bc_list [@bc_1, @bc_4]
    @rules [@rule]
    @results [@resut_1, @resut_2]

    defp list_of_events_to_dipatch do
      event_1 = %{
        user_id: 42,
        user_name: "some name",
        service: "bg",
        event: "create_comment",
        resource_id: 1,
        resource_type: "comment",
        ts: "2018-01-24 23:53:07Z",
        payload: %{
          "content" => "My awesome comment 1",
          "resource_id" => 1,
          "resource_type" => "business_concept"
        }
      }

      event_2 = %{
        user_id: 42,
        user_name: "some name",
        service: "bg",
        event: "create_comment",
        resource_id: 2,
        resource_type: "comment",
        ts: "2018-01-24 23:52:07Z",
        payload: %{
          "content" => "My awesome comment 2",
          "resource_id" => 2,
          "resource_type" => "business_concept"
        }
      }

      event_3 = %{
        user_id: 42,
        user_name: "some name",
        service: "bg",
        event: "create_comment",
        resource_id: 3,
        resource_type: "comment",
        ts: "2018-01-22 20:50:07Z",
        payload: %{
          "content" => "My awesome comment 3",
          "resource_id" => 3,
          "resource_type" => "business_concept"
        }
      }

      event_4 = %{
        user_id: 42,
        user_name: "some name",
        event: "create_comment",
        service: "bg",
        resource_id: 4,
        resource_type: "comment",
        ts: "2018-01-24 23:51:07Z",
        payload: %{
          "content" => "My awesome comment 4",
          "resource_id" => 4,
          "resource_type" => "business_concept"
        }
      }

      [event_1, event_2, event_3, event_4]
    end

    defp list_of_subscriptions(:email_on_comment) do
      # This subscription is one to be sent resource_id => 1
      subscription_1 = %{
        event: "create_comment",
        user_email: "mymail1@foo.bar",
        resource_type: "business_concept",
        last_consumed_event: "2018-01-23 21:50:07Z",
        resource_id: 1
      }

      subscription_2 = %{
        event: "create_comment",
        user_email: "mymail1@foo.bar",
        resource_type: "business_concept",
        last_consumed_event: "2018-01-23 21:50:07Z",
        resource_id: 3
      }

      # This subscription is one to be sent resource_id => 1
      subscription_3 = %{
        event: "create_comment",
        user_email: "mymail2@foo.bar",
        resource_id: 1,
        resource_type: "business_concept",
        last_consumed_event: "2018-01-23 21:50:07Z"
      }

      # This subscription is one to be sent resource_id => 4
      subscription_4 = %{
        event: "create_comment",
        user_email: "mymail3@foo.bar",
        resource_id: 4,
        resource_type: "business_concept",
        last_consumed_event: "2018-01-23 21:50:07Z"
      }

      [subscription_1, subscription_2, subscription_3, subscription_4]
    end

    defp list_of_subscriptions(:failed_rule_results) do
      subscription_1 = %{
        event: "failed_rule_results",
        user_email: "mymail1@foo.bar",
        resource_type: "business_concept",
        last_consumed_event: DateTime.utc_now(),
        resource_id: @bc_4["id"]
      }

      subscription_2 = %{
        event: "failed_rule_results",
        user_email: "mymail2@foo.bar",
        resource_type: "business_concept",
        last_consumed_event: DateTime.utc_now(),
        resource_id: @bc_4["id"]
      }

      [subscription_1, subscription_2]
    end
  end

  defp create_users_in_cache do
    @user_list
    |> Enum.map(&Map.take(&1, ["id", "email", "user_name", "full_name"]))
    |> Enum.map(&atomize_keys/1)
    |> Enum.map(&UserCache.put/1)
  end

  defp create_bcs_in_cache do
    @bc_list
    |> Enum.map(&Map.take(&1, ["id", "name", "domain_id", "business_concept_version_id"]))
    |> Enum.map(&atomize_keys/1)
    |> Enum.map(&ConceptCache.put/1)
  end

  defp rules_in_cache do
    Enum.map(@rules, &RuleCache.put/1)
  end

  defp rule_results_in_cache do
    resuls = Enum.map(@results, &RuleResultCache.put/1)
    RuleResultCache.update_failed_ids(Enum.map(@results, & &1.id))
    {:ok, resuls}
  end

  defp atomize_keys(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
  end

  defp events_fixture do
    list_of_events_to_dipatch()
    |> Enum.map(&Audit.create_event(&1))
  end

  defp subscriptions_fixture(event) do
    event
    |> list_of_subscriptions()
    |> Enum.map(&Subscriptions.create_subscription(&1))
    |> Enum.map(fn {:ok, value} -> value end)
  end

  defp prepare_cache(:email_on_comment) do
    create_users_in_cache()
    create_bcs_in_cache()
  end

  defp prepare_cache(:failed_rule_results) do
    create_users_in_cache()
    create_bcs_in_cache()
    rules_in_cache()
    rule_results_in_cache()
  end

  defp dispatch_notification_fixture do
    {events_fixture(), subscriptions_fixture(:email_on_comment)}
  end

  test "dispatch_notification/1 on create comment" do
    prepare_cache(:email_on_comment)
    consumed_subscriptions = [1, 4]
    {_events_list, subs_list} = dispatch_notification_fixture()
    to_format_resource_id_1 = [nil: "mymail1@foo.bar", nil: "mymail2@foo.bar"]
    to_format_resource_id_2 = [nil: "mymail3@foo.bar"]

    list_sent_notifications =
      NotificationDispatcher.dispatch_notification(
        {:dispatch_on_comment_creation, "create_comment"}
      )

    assert length(list_sent_notifications) == 2

    assert Enum.any?(list_sent_notifications, fn el ->
             Map.fetch!(el, :to) == to_format_resource_id_1
           end)

    assert Enum.any?(list_sent_notifications, fn el ->
             Map.fetch!(el, :to) == to_format_resource_id_2
           end)

    existing_subs = Subscriptions.list_subscriptions()

    assert existing_subs
           |> Enum.filter(&(Map.get(&1, :resource_id) in consumed_subscriptions))
           |> Enum.all?(fn sb ->
             prior_sub = Enum.find(subs_list, &(sb.id == &1.id))
             prior_sub.last_consumed_event < sb.last_consumed_event
           end)
  end

  test "dispatch_notification/1 on failed rule results" do
    prepare_cache(:failed_rule_results)
    subscriptions_fixture(:failed_rule_results)

    expected_mails = [[nil: "mymail1@foo.bar"], [nil: "mymail2@foo.bar"]]

    sent_notifications =
      NotificationDispatcher.dispatch_notification(
        {:dispatch_on_failed_results, "failed_rule_results"}
      )

    assert length(sent_notifications) == 2
    assert Enum.all?(sent_notifications, &(Map.get(&1, :to) in expected_mails))
  end
end
