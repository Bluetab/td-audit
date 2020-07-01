defmodule TdAudit.Subscriptions.SubscribersTest do
  use TdAudit.DataCase

  alias TdAudit.Subscriptions.Subscribers

  describe "list_subscribers/0" do
    test "returns a list of all subscribers" do
      subscriber = insert(:subscriber)

      assert Subscribers.list_subscribers() == [subscriber]
    end
  end

  describe "get_subscriber!/1" do
    test "returns a subscribers" do
      %{id: id} = subscriber = insert(:subscriber)

      assert Subscribers.get_subscriber!(id) == subscriber
    end
  end

  describe "create_subscriber/1" do
    test "creates a subscriber" do
      params = string_params_for(:subscriber)

      assert {:ok, _subscriber} = Subscribers.create_subscriber(params)
    end
  end

  describe "delete_subscriber/1" do
    test "deletes a subscriber" do
      subscriber = insert(:subscriber)

      assert {:ok, %{__meta__: meta}} = Subscribers.delete_subscriber(subscriber)
      assert %{state: :deleted} = meta
    end
  end
end
