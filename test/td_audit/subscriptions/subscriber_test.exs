defmodule TdAudit.Subscriptions.SubscriberTest do
  use TdAudit.DataCase

  alias TdAudit.Repo
  alias TdAudit.Subscriptions.Subscriber

  describe "changeset/2" do
    test "validates inclusion on type" do
      params = params_for(:subscriber, type: "foo")

      assert %{valid?: false, errors: errors} = Subscriber.changeset(params)
      assert {_message, [validation: :inclusion, enum: ["email", "user", "role"]]} = errors[:type]
    end

    test "validates unique constraint on type and identifier" do
      subscriber = insert(:subscriber)

      assert {:error, changeset} =
               subscriber
               |> Map.take([:type, :identifier])
               |> Subscriber.changeset()
               |> Repo.insert()

      assert %{valid?: false, errors: errors} = changeset

      assert {_message,
              [constraint: :unique, constraint_name: "subscribers_type_identifier_index"]} =
               errors[:unique_subscriber]
    end
  end
end
