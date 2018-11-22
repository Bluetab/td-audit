defmodule TdAudit.NotificationDispatcherTest do
  @moduledoc """
  Testing of the module TdAudit.NotificationDispatcher
  """
  use ExUnit.Case
  use Bamboo.Test
  alias TdAudit.Audit
  use TdAudit.DataCase
  alias TdAudit.NotificationDispatcher
  alias TdAudit.Subscriptions
  alias TdPerms.BusinessConceptCacheMock
  alias TdPerms.UserCacheMock

  setup_all do
    start_supervised(UserCacheMock)
    start_supervised(BusinessConceptCacheMock)
    :ok
  end

  describe "notification_dispatcher" do
    @user_1 %{"id" => 42, "user_name" => "my_user_name", "email" => "my_user_email@foo.bar"}
    @bc_1 %{"id" => 1, "name" => "BC Name 1", "business_concept_version_id" => 1}
    @bc_4 %{"id" => 4, "name" => "BC Name 4", "business_concept_version_id" => 1}

    @user_list [@user_1]
    @bc_list [@bc_1, @bc_4]

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

    defp list_of_subscriptions do
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
  end

  defp create_users_in_cache do
    @user_list
    |> Enum.map(&Map.take(&1, ["id", "email", "user_name", "full_name"]))
    |> Enum.map(&UserCacheMock.put_user_in_cache(&1))
  end

  defp create_bcs_in_cache do
    @bc_list
    |> Enum.map(&Map.take(&1, ["id", "name"]))
    |> Enum.map(&BusinessConceptCacheMock.put_bc_in_cache(&1))
  end

  defp events_fixture do
    list_of_events_to_dipatch()
    |> Enum.map(&Audit.create_event(&1))
  end

  defp subscriptions_fixture do
    list_of_subscriptions()
    |> Enum.map(&Subscriptions.create_subscription(&1))
    |> Enum.map(fn {:ok, value} -> value end)
  end

  defp prepare_cache do
    create_users_in_cache()
    create_bcs_in_cache()
  end

  defp dispatch_notification_fixture do
    {events_fixture(), subscriptions_fixture()}
  end

  test "dispatch_notification/0" do
    prepare_cache()
    {_events_list, subs_list} = dispatch_notification_fixture()
    to_format_resource_id_1 = [nil: "mymail1@foo.bar", nil: "mymail2@foo.bar"]
    to_format_resource_id_2 = [nil: "mymail3@foo.bar"]
    list_sent_notifications =
      NotificationDispatcher.dispatch_notification(
        {:dispatch_on_comment_creation, "create_comment"}
      )

    assert length(list_sent_notifications) == 2
    Enum.any?(list_sent_notifications, fn el -> Map.fetch!(el, :to) == to_format_resource_id_1 end)
    Enum.any?(list_sent_notifications, fn el -> Map.fetch!(el, :to) == to_format_resource_id_2 end)
    existing_subs = Subscriptions.list_subscriptions()
    Enum.all?(existing_subs, fn sb ->
      prior_sub = Enum.find(subs_list, &(sb.id == &1.id))
      prior_sub.last_consumed_event < sb.last_consumed_event
    end)
  end
end
