defmodule TdAudit.Subscriptions.SubscriptionTest do
  use TdAudit.DataCase

  alias Ecto.Changeset
  alias TdAudit.Subscriptions.Subscription

  describe "changeset/2" do
    test "validates scope is present" do
      params = %{}
      assert %{errors: errors} = Subscription.changeset(params)
      assert {"can't be blank", [validation: :required]} = errors[:scope]
    end

    test "validates scope using Scope.changeset/2" do
      params = %{scope: %{"foo" => 42}}

      assert %{scope: scope_errors} =
               params
               |> Subscription.changeset()
               |> Changeset.traverse_errors(& &1)

      assert %{events: [{"can't be blank", [validation: :required]}]} = scope_errors
    end
  end
end
