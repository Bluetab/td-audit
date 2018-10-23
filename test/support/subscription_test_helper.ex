defmodule TdAudit.SubscriptionTestHelper do
  @moduledoc """
  This module will implement some functions used in
  subscriptions tests
  """
  alias TdAudit.Subscriptions

  @valid_attrs %{
    event: "some event",
    resource_id: 42,
    resource_type: "some resource_type",
    user_email: "mymail@foo.com",
    periodicity: "daily"
  }

  @invalid_attrs %{
    event: "some event",
    resource_id: 42,
    resource_type: "some resource_type",
    periodicity: "daily"
  }

  def create_subscription(attrs \\ %{}) do
    {:ok, subscription} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Subscriptions.create_subscription()

    {:ok, subscription: subscription}
  end

  def subscription_fixture(attrs \\ %{}) do
    {:ok, subscription} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Subscriptions.create_subscription()

    subscription
  end

  def subscription_view_fixture(attrs \\ %{}) do
    {:ok, subscription: subscription} = create_subscription(attrs)

    subscription
    |> Map.from_struct()
    |> Map.drop([:__meta__, :updated_at, :inserted_at])
    |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, Atom.to_string(key), val) end)
  end

  def retrieve_valid_attrs, do: @valid_attrs

  def retrieve_invalid_attrs, do: @invalid_attrs
end
