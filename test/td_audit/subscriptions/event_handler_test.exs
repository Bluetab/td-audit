defmodule TdAudit.Subscriptions.EventHandlerTest do
  use TdAudit.DataCase

  alias TdAudit.Subscriptions.EventHandler

  setup_all do
    start_supervised!(EventHandler)
    :ok
  end

  describe "after_insert" do
    test "returns {:ok, event} tuple" do
      event = insert(:event)
      assert {:ok, ^event} = EventHandler.after_insert(event)
    end
  end
end
