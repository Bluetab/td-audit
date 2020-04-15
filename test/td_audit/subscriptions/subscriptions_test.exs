defmodule TdAudit.SubscriptionsTest do
  @moduledoc """
  Subscriptions testing module
  """
  use TdAudit.DataCase

  alias TdAudit.Audit
  alias TdAudit.Subscriptions

  describe "subscriptions" do
    alias TdAudit.Subscriptions.Subscription

    @event_attrs %{
      event: "some event",
      payload: %{},
      resource_id: 42,
      resource_type: "some resource_type",
      service: "some service",
      ts: "2010-04-17 14:00:00.000Z",
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
      subscription = insert(:subscription)
      assert Subscriptions.list_subscriptions() == [subscription]
    end

    test "list_subscriptions/1 returns all subscriptions filtered by resource_id" do
      target_resource_id = 44
      insert(:subscription)
      s1 = insert(:subscription, resource_id: 44, event: "my event")
      s2 = insert(:subscription, resource_id: 44, event: "my event")

      assert Subscriptions.list_subscriptions_by_filter(%{
               "resource_id" => target_resource_id,
               "event" => ["my event"]
             }) == [s1, s2]
    end

    test "get_subscription!/1 returns the subscription with given id" do
      subscription = insert(:subscription)
      assert Subscriptions.get_subscription!(subscription.id) == subscription
    end

    test "create_subscription/1 with valid data creates a event" do
      fields = [:event, :resource_id, :resource_type, :user_email, :periodicity]
      params = build(:subscription) |> Map.take(fields)

      assert {:ok, %Subscription{} = subscription} = Subscriptions.create_subscription(params)

      assert Map.take(subscription, fields) == params
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      params = build(:subscription) |> Map.from_struct() |> Map.delete(:user_email)

      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_subscription(params)
    end

    test "update_subscription/2 with valid data updates the subscription" do
      new_resource_id = 44
      new_resource_type = "new resource type"
      subscription = insert(:subscription)

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
      subscription = insert(:subscription)

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.update_subscription(subscription, %{"resource_id" => nil})

      assert subscription == Subscriptions.get_subscription!(subscription.id)
    end

    test "delete_subscription/1 deletes the subscription" do
      subscription = insert(:subscription)
      assert {:ok, %Subscription{}} = Subscriptions.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Subscriptions.get_subscription!(subscription.id) end
    end
  end
end
