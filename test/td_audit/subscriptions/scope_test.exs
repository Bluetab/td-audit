defmodule TdAudit.Subscriptions.ScopeTest do
  use ExUnit.Case

  alias TdAudit.Subscriptions.Scope

  describe "changeset/2" do
    test "validates events is a non-empty array" do
      params = %{events: []}
      assert %{errors: errors} = Scope.changeset(params)

      assert {_message, [count: 1, validation: :length, kind: :min, type: :list]} =
               errors[:events]
    end

    test "validates status if events is rule_result_created" do
      params = %{
        events: ["rule_result_created"],
        status: ["warning"],
        resource_type: "domain",
        resource_id: 42
      }

      assert %{errors: errors} = Scope.changeset(params)

      assert {_message,
              [
                validation: :inclusion,
                enum: ["fail", "success", "warn", "error", "empty_dataset"]
              ]} = errors[:status]
    end
  end
end
