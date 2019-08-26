defmodule TdAudit.SubscriptionEventProcessorTest do
  @moduledoc """
  This module will test the creation and deletion of subscription
  under the arrival of an event
  """
  use ExUnit.Case, async: false
  use TdAudit.DataCase

  import TdAudit.SubscriptionTestHelper

  alias TdAudit.NotificationsSystem
  alias TdAudit.SubscriptionEventProcessor
  alias TdAudit.Subscriptions
  alias TdCache.UserCache

  @user_1 %{
    "id" => 1,
    "user_name" => "my_user_name",
    "full_name" => "full_name",
    "email" => "my_user_email@foo.bar"
  }
  @user_2 %{
    "id" => 2,
    "user_name" => "my_user_name_2",
    "full_name" => "full_name_2",
    "email" => "my_user_email_2@foo.bar"
  }
  @user_3 %{
    "id" => 3,
    "user_name" => "my_user_name_3",
    "full_name" => "full_name_3",
    "email" => "my_user_email_3@foo.bar"
  }

  @user_list [@user_1, @user_2, @user_3]

  defp process_event_fixture do
    create_configurations()
    create_users_in_cache()
    create_list_of_events_for_process()
  end

  defp create_configurations do
    {:ok, conf_1} =
      NotificationsSystem.create_configuration(%{
        event: "create_concept_draft",
        settings: %{
          "generate_subscription" => %{
            "roles" => ["data_owner"],
            "target_event" => "create_comment"
          }
        }
      })

    {:ok, conf_2} =
      NotificationsSystem.create_configuration(%{
        event: "create_concept_draft",
        settings: %{
          "generate_subscription" => %{
            "roles" => ["data_owner"],
            "target_event" => "failed_rule_results"
          }
        }
      })

    [conf_1, conf_2]
  end

  defp create_users_in_cache do
    @user_list
    |> Enum.map(&Map.take(&1, ["id", "email", "full_name", "user_name"]))
    |> Enum.map(&Map.new(&1, fn {k, v} -> {String.to_atom(k), v} end))
    |> Enum.map(&UserCache.put/1)
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

    assert length(created_subscriptions) == 6

    assert Enum.all?(
             created_subscriptions,
             &(Map.get(&1, :event) in ["create_comment", "failed_rule_results"] &&
                 Map.get(&1, :resource_type) == "business_concept")
           )

    assert Enum.all?(valid_ids, fn id ->
             Enum.any?(created_subscriptions, &(Map.get(&1, :resource_id) == id))
           end)
  end

  test "process_event/1 for event delete_concept_draft" do
    subscription_fixture(%{
      resource_id: 1,
      event: "create_comment",
      resource_type: "business_concept"
    })

    remaining_subscription_1 =
      subscription_fixture(%{
        resource_id: 2,
        event: "create_comment",
        resource_type: "business_concept"
      })

    remaining_subscription_2 =
      subscription_fixture(%{
        resource_id: 3,
        event: "create_comment",
        resource_type: "business_concept"
      })

    remaining_subscriptions = [remaining_subscription_1, remaining_subscription_2]

    SubscriptionEventProcessor.process_event(%{
      "resource_id" => 1,
      "event" => "delete_concept_draft",
      "resource_type" => "some resource_type"
    })

    subscriptions = Subscriptions.list_subscriptions()
    assert length(subscriptions) == 2

    assert Enum.all?(remaining_subscriptions, fn s ->
             Enum.any?(subscriptions, &(Map.get(&1, :resource_id) == Map.get(s, :resource_id)))
           end)
  end

  test "process_event/1 for update_concept_draft" do
    del_sub =
      subscription_fixture(%{
        resource_id: 1,
        event: "create_comment",
        resource_type: "business_concept"
      })

    sub_1 =
      subscription_fixture(%{
        resource_id: 2,
        event: "create_comment",
        resource_type: "business_concept"
      })

    sub_2 =
      subscription_fixture(%{
        resource_id: 3,
        event: "create_comment",
        resource_type: "business_concept"
      })

    remaining_subscriptions = [sub_1, sub_2]
    event_fixture = hd(process_event_fixture())

    content =
      event_fixture
      |> Map.get("payload")
      |> Map.get("content")

    new_payload =
      Map.new()
      |> Map.put("content", Map.new() |> Map.put("changed", content))

    event_fixture =
      event_fixture
      |> Map.put("event", "update_concept_draft")
      |> Map.put("payload", new_payload)

    SubscriptionEventProcessor.process_event(event_fixture)

    subscriptions = Subscriptions.list_subscriptions()
    assert length(subscriptions) == 4

    assert not Enum.any?(subscriptions, &(Map.get(&1, :id) == Map.get(del_sub, :id)))

    assert Enum.all?(remaining_subscriptions, fn s ->
             Enum.any?(subscriptions, &(Map.get(&1, :resource_id) == Map.get(s, :resource_id)))
           end)
  end
end
