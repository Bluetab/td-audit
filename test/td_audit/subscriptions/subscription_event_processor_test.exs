defmodule TdAudit.SubscriptionEventProcessorTest do
  @moduledoc """
  This module will test the creation and deletion of subscription
  under the arrival of an event
  """
  use ExUnit.Case, async: false
  use TdAudit.DataCase
  alias TdAudit.NotificationsSystem
  alias TdAudit.SubscriptionEventProcessor
  alias TdAudit.Subscriptions
  import TdAudit.SubscriptionTestHelper
  alias TdPerms.UserCacheMock

  @user_1 %{"id" => 1, "user_name" => "my_user_name", "full_name" => "full_name", "email" => "my_user_email@foo.bar"}
  @user_2 %{"id" => 2, "user_name" => "my_user_name_2", "full_name" => "full_name_2", "email" => "my_user_email_2@foo.bar"}
  @user_3 %{"id" => 3, "user_name" => "my_user_name_3", "full_name" => "full_name_3", "email" => "my_user_email_3@foo.bar"}

  @user_list [@user_1, @user_2, @user_3]

  @conf_create_attrs %{
    event: "create_concept_draft",
    settings: %{
      "generate_subscription" => %{
        "roles" => ["data_owner"]
      }
    }
  }

  setup_all do
    start_supervised(UserCacheMock)
    :ok
  end

  defp process_event_fixture do
    create_configuration()
    create_users_in_cache()
    create_list_of_events_for_process()
  end

  defp create_configuration do
    {:ok, configuration} =
      @conf_create_attrs
      |> NotificationsSystem.create_configuration()

    configuration
  end

  defp create_users_in_cache do
    @user_list
    |> Enum.map(&Map.take(&1, ["id", "email", "full_name"]))
    |> Enum.map(&UserCacheMock.put_user_in_cache(&1))
  end

  defp create_list_of_events_for_process do
    user_1 = @user_1 |> Map.get("full_name")
    user_2 = @user_2 |> Map.get("full_name")
    user_3 = @user_3 |> Map.get("full_name")

    event_1 = %{
      "event" => "create_concept_draft",
      "resource_id" => 1,
      "resource_type" => "concept",
      "payload" => %{"content" => %{"data_owner" => user_1}}
    }

    event_2 = %{
      "event" => "create_concept_draft",
      "resource_id" => 2,
      "resource_type" => "concept",
      "payload" => %{"content" => %{"data_owner" => user_2}}
    }

    event_3 = %{
      "event" => "create_concept_draft",
      "resource_id" => 3,
      "resource_type" => "concept",
      "payload" => %{"content" => %{"data_owner" => user_3}}
    }

    event_4 = %{
      "event" => "create_concept_draft",
      "resource_id" => 4,
      "resource_type" => "concept",
      "payload" => %{"content" => %{"made_up_role" => user_3}}
    }

    [event_1, event_2, event_3, event_4]
  end

  test "process_event/1 for event create_concept_draft" do
    process_event_fixture()
    |> Enum.map(&SubscriptionEventProcessor.process_event(&1))

    valid_ids = [1, 2, 3]
    created_subscriptions = Subscriptions.list_subscriptions()
    assert length(created_subscriptions) == 3

    assert Enum.all?(
             created_subscriptions,
             &(Map.get(&1, :event) == "create_comment" && Map.get(&1, :resource_type) == "business_concept")
           )

    assert Enum.all?(valid_ids, fn id ->
             Enum.any?(created_subscriptions, &(Map.get(&1, :resource_id) == id))
           end)
  end

  test "process_event/1 for event delete_concept_draft" do
    subscription_fixture(%{resource_id: 1, event: "create_comment"})
    remaining_subscription_1 = subscription_fixture(%{resource_id: 2, event: "create_comment"})
    remaining_subscription_2 = subscription_fixture(%{resource_id: 3, event: "create_comment"})
    remaining_subscriptions = [remaining_subscription_1, remaining_subscription_2]

    SubscriptionEventProcessor.process_event(%{
      "resource_id" => 1,
      "event" => "delete_concept_draft",
      "resource_type" => "some resource_type"
    })

    subscriptions = Subscriptions.list_subscriptions()
    assert length(remaining_subscriptions) == 2

    assert Enum.all?(remaining_subscriptions, fn s ->
             Enum.any?(subscriptions, &(Map.get(&1, :resource_id) == Map.get(s, :resource_id)))
           end)
  end
end
