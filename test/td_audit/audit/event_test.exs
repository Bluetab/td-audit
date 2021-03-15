defmodule TdAudit.Audit.EventTest do
  use ExUnit.Case

  alias TdAudit.Audit.Event

  describe "changeset/2" do
    test "requires user and resource if type is not login_attempt" do
      params = %{event: "foo"}
      assert %{errors: errors} = Event.changeset(params)
      assert errors[:user_id]
      assert errors[:resource_type]
      assert errors[:resource_id]
    end

    test "does not require user nor resource if type is login_attempt" do
      params = %{event: "login_attempt"}
      assert %{errors: errors} = Event.changeset(params)
      refute errors[:user_id]
      refute errors[:resource_type]
      refute errors[:resource_id]
    end

    test "does not require user_id if type is login_success" do
      params = %{event: "login_attempt"}
      assert %{errors: errors} = Event.changeset(params)
      refute errors[:user_id]
    end

    test "renames resource_type from business_concept to concept" do
      params = %{"resource_type" => "business_concept"}
      assert %{changes: changes} = Event.changeset(params)
      assert %{resource_type: "concept"} = changes
    end

    test "preserves resource_type for values other than business_concept" do
      params = %{"resource_type" => "foo"}
      assert %{changes: changes} = Event.changeset(params)
      assert %{resource_type: "foo"} = changes
    end
  end
end
