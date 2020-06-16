defmodule TdAudit.Subscriptions.EventProcessorTest do
  @moduledoc """
  This module will test the creation and deletion of subscription
  under the arrival of an event
  """
  use ExUnit.Case, async: false
  use TdAudit.DataCase

  alias TdAudit.NotificationsSystem
  alias TdAudit.Subscriptions
  alias TdAudit.Subscriptions.EventProcessor
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
            "target_event" => "comment_created"
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
      event: "create_concept_draft",
      resource_id: 1,
      resource_type: "concept",
      payload: %{"content" => %{"data_owner" => user_1}}
    }

    event_2 = %{
      event: "create_concept_draft",
      resource_id: 2,
      resource_type: "concept",
      payload: %{"content" => %{"data_owner" => user_2}}
    }

    event_3 = %{
      event: "create_concept_draft",
      resource_id: 3,
      resource_type: "concept",
      payload: %{"content" => %{"data_owner" => user_3}}
    }

    event_4 = %{
      event: "create_concept_draft",
      resource_id: 4,
      resource_type: "concept",
      payload: %{"content" => %{"made_up_role" => user_3}}
    }

    [event_1, event_2, event_3, event_4]
  end

  test "process_event/1 for event create_concept_draft" do
    process_event_fixture()
    |> Enum.map(&EventProcessor.process_event/1)

    valid_ids = [1, 2, 3]
    created_subscriptions = Subscriptions.list_subscriptions()

    assert length(created_subscriptions) == 6

    assert Enum.all?(
             created_subscriptions,
             &(Map.get(&1, :event) in ["comment_created", "failed_rule_results"] &&
                 Map.get(&1, :resource_type) == "business_concept")
           )

    assert Enum.all?(valid_ids, fn id ->
             Enum.any?(created_subscriptions, &(Map.get(&1, :resource_id) == id))
           end)
  end

  test "process_event/1 for event delete_concept_draft" do
    [s1, s2, s3] =
      Enum.map(1..3, fn _ ->
        insert(:subscription, event: "delete_concept_draft", resource_type: "business_concept")
      end)

    EventProcessor.process_event(%{
      resource_id: s1.resource_id,
      event: "delete_concept_draft",
      resource_type: "business_concept"
    })

    subscriptions = Subscriptions.list_subscriptions()
    assert length(subscriptions) == 2

    assert Enum.all?([s2, s3], fn s ->
             Enum.any?(subscriptions, &(Map.get(&1, :resource_id) == Map.get(s, :resource_id)))
           end)
  end

  test "process_event/1 for update_concept_draft" do
    %{id: id1} =
      insert(:subscription,
        resource_id: 1,
        event: "comment_created",
        resource_type: "business_concept"
      )

    sub_1 =
      insert(:subscription,
        resource_id: 2,
        event: "comment_created",
        resource_type: "business_concept"
      )

    sub_2 =
      insert(:subscription,
        resource_id: 3,
        event: "comment_created",
        resource_type: "business_concept"
      )

    remaining_subscriptions = [sub_1, sub_2]

    [event | _] = process_event_fixture()

    %{payload: %{"content" => content}} = event

    event = %{
      event
      | event: "update_concept_draft",
        payload: %{"content" => %{"changed" => content}}
    }

    EventProcessor.process_event(event)

    subscriptions = Subscriptions.list_subscriptions()
    assert length(subscriptions) == 4

    refute subscriptions
           |> Enum.map(& &1.id)
           |> Enum.member?(id1)

    assert Enum.all?(remaining_subscriptions, fn s ->
             Enum.any?(subscriptions, &(Map.get(&1, :resource_id) == Map.get(s, :resource_id)))
           end)
  end
end
