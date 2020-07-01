defmodule TdAudit.SubscriptionsTest do
  @moduledoc """
  Subscriptions testing module
  """
  use TdAudit.DataCase

  import TdAudit.TestOperators

  alias TdAudit.Subscriptions

  describe "subscriptions" do
    alias TdAudit.Subscriptions.Subscription

    test "list_subscriptions/0 returns all subscriptions" do
      subscription = insert(:subscription)
      assert Subscriptions.list_subscriptions() <|> [subscription]
    end

    test "list_subscriptions/1 returns all subscriptions filtered by resource_id" do
      %{id: subscriber_id} = insert(:subscriber)

      insert(:subscription)
      s1 = insert(:subscription, subscriber_id: subscriber_id)
      s2 = insert(:subscription, subscriber_id: subscriber_id)

      assert Subscriptions.list_subscriptions(subscriber_id: subscriber_id) <|> [s1, s2]
    end

    test "get_subscription!/1 returns the subscription with given id" do
      subscription = insert(:subscription)
      assert Subscriptions.get_subscription!(subscription.id) <~> subscription
    end

    test "create_subscription/1 with valid data creates a subscription" do
      %{id: subscriber_id} = insert(:subscriber)

      params =
        :subscription
        |> string_params_for(subscriber_id: subscriber_id)
        |> Map.take(["subscriber_id", "scope", "periodicity"])

      assert {:ok, %Subscription{} = _subscription} = Subscriptions.create_subscription(params)
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_subscription(%{})
    end

    test "delete_subscription/1 deletes the subscription" do
      subscription = insert(:subscription)
      assert {:ok, %Subscription{}} = Subscriptions.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Subscriptions.get_subscription!(subscription.id) end
    end
  end
end
