defmodule TdAudit.SubscriptionsTest do
  @moduledoc """
  Subscriptions testing module
  """
  alias TdAudit.Audit
  use TdAudit.DataCase
  alias TdAudit.Subscriptions
  import TdAudit.SubscriptionTestHelper

  describe "subscriptions" do
    alias TdAudit.Subscriptions.Subscription

    @event_attrs %{
      event: "some event",
      payload: %{},
      resource_id: 42,
      resource_type: "some resource_type",
      service: "some service",
      ts: "2010-04-17 14:00:00.000000Z",
      user_id: 42,
      user_name: "some name"
    }

    def event_fixture(attrs \\ %{}) do
      {:ok, event} =
        attrs
        |> Enum.into(@event_attrs)
        |> Audit.create_event()

      event
    end

    test "list_subscriptions/0 returns all subscriptions" do
      subscription = subscription_fixture()
      assert Subscriptions.list_subscriptions() == [subscription]
    end

    test "list_subscriptions/1 returns all subscriptions filtered by resource_id" do
      target_resource_id = 44
      subscription_fixture()
      subscription = subscription_fixture(%{resource_id: target_resource_id})

      assert Subscriptions.list_subscriptions_by_filter(%{"resource_id" => target_resource_id}) ==
               [subscription]
    end

    test "get_subscription!/1 returns the subscription with given id" do
      subscription = subscription_fixture()
      assert Subscriptions.get_subscription!(subscription.id) == subscription
    end

    test "create_subscription/1 with valid data creates a event" do
      assert {:ok, %Subscription{} = subscription} =
               Subscriptions.create_subscription(retrieve_valid_attrs())

      assert subscription.event == "some event"
      assert subscription.resource_id == 42
      assert subscription.resource_type == "some resource_type"
      assert subscription.user_email == "mymail@foo.com"
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_subscription(retrieve_invalid_attrs())
    end

    test "update_subscription/2 with valid data updates the subscription" do
      new_resource_id = 44
      new_resource_type = "new resource type"
      subscription = subscription_fixture()

      assert {:ok, subscription} =
               Subscriptions.update_subscription(subscription, %{
                 "resource_id" => new_resource_id,
                 "resource_type" => new_resource_type
               })

      assert %Subscription{} = subscription
      assert subscription.resource_id == new_resource_id
      assert subscription.resource_type == new_resource_type
    end

    test "update_subscription/2 with invalid data returns error changeset" do
      subscription = subscription_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.update_subscription(subscription, %{"resource_id" => nil})

      assert subscription == Subscriptions.get_subscription!(subscription.id)
    end

    test "delete_subscription/1 deletes the subscription" do
      subscription = subscription_fixture()
      assert {:ok, %Subscription{}} = Subscriptions.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Subscriptions.get_subscription!(subscription.id) end
    end

    test "change_subscription/1 returns a subscription changeset" do
      subscription = subscription_fixture()
      assert %Ecto.Changeset{} = Subscriptions.change_subscription(subscription)
    end
  end
end
