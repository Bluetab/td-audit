defmodule TdAudit.NotificationDispatcherTest do
  @moduledoc """
  Testing of the module TdAudit.NotificationDispatcher
  """
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
    @bc_1 %{"id" => 1, "name" => "BC Name"}

    @user_list [@user_1]
    @bc_list [@bc_1]

    defp create_users_in_cache do
      @user_list
      |> Enum.map(&Map.take(&1, ["id", "email", "user_name"]))
      |> Enum.map(&UserCacheMock.put_user_in_cache(&1))
    end

    defp create_bcs_in_cache do
      @bc_list
      |> Enum.map(&Map.take(&1, ["id", "name"]))
      |> Enum.map(&BusinessConceptCacheMock.put_bc_in_cache(&1))
    end

    defp list_of_events_to_dipatch do
      # This event will generate an email
      event_1 = %{
        user_id: 42,
        user_name: "some name",
        service: "bg",
        event: "create_comment",
        resource_id: 1,
        resource_type: "comment",
        ts: "2018-01-24 23:50:07Z",
        payload: %{"content" => "My awesome comment 1", "resource_id" => 1, "resource_type" => "business_concept"}
      }

      event_2 = %{
        user_id: 42,
        user_name: "some name",
        service: "bg",
        event: "create_comment",
        resource_id: 2,
        resource_type: "comment",
        ts: "2018-01-24 23:50:07Z",
        payload: %{"content" => "My awesome comment 2", "resource_id" => 2, "resource_type" => "business_concept"}
      }

      event_3 = %{
        user_id: 42,
        user_name: "some name",
        service: "bg",
        event: "create_comment",
        resource_id: 3,
        resource_type: "comment",
        ts: "2018-01-22 20:50:07Z",
        payload: %{"content" => "My awesome comment 3", "resource_id" => 3, "resource_type" => "business_concept"}
      }

      event_4 = %{
        user_id: 42,
        user_name: "some name",
        event: "create_comment",
        service: "bg",
        resource_id: 4,
        resource_type: "comment",
        ts: "2018-01-24 23:50:07Z",
        payload: %{"content" => "My awesome comment 4", "resource_id" => 4, "resource_type" => "business_concept"}
      }

      [event_1, event_2, event_3, event_4]
    end

    defp list_of_subscriptions do
      # This subscription is the one to be sent
      subscription_1 = %{
        event: "create_comment",
        user_email: "mymail1@foo.bar",
        resource_type: "business_concept",
        last_consumed_event:  "2018-01-23 21:50:07Z",
        resource_id: 1
      }

      subscription_2 = %{
        event: "create_comment",
        user_email: "mymail1@foo.bar",
        resource_type: "business_concept",
        last_consumed_event:  "2018-01-23 21:50:07Z",
        resource_id: 3
      }

      subscription_3 = %{
        event: "create_comment",
        user_email: "mymail2@foo.bar",
        resource_id: 5,
        resource_type: "business_concept",
        last_consumed_event: "2018-01-23 21:50:07Z"
      }

      subscription_4 = %{
        event: "create_comment",
        user_email: "mymail3@foo.bar",
        resource_id: 4,
        resource_type: "comment",
        last_consumed_event: "2018-01-23 21:50:07Z"
      }

      [subscription_1, subscription_2, subscription_3, subscription_4]
    end
  end

  defp events_fixture do
    list_of_events_to_dipatch() |> Enum.map(&Audit.create_event(&1))
  end

  defp subscriptions_fixture do
    list_of_subscriptions() |> Enum.map(&Subscriptions.create_subscription(&1))
  end

  test "dispatch_notification/0" do
    create_users_in_cache()
    create_bcs_in_cache()
    events_fixture()
    subscriptions_fixture()
    NotificationDispatcher.dispatch_notification({:dispatch_on_comment_creation, "create_comment"})
  end
end
