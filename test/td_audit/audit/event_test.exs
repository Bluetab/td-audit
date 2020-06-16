defmodule TdAudit.Audit.EventTest do
  use ExUnit.Case

  alias TdAudit.Audit.Event

  describe "changeset/2" do
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
