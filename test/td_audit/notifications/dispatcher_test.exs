defmodule TdAudit.Notifications.DispatcherTest do
  use TdAudit.DataCase

  alias TdAudit.Notifications.Dispatcher

  describe "init/1" do
    test "returns initial state" do
      assert {:ok, :no_state} = Dispatcher.init(:unused)
    end
  end

  describe "dispatch/1 with message" do
    test "processes message without errors" do
      message = %{event: "test_event", user_id: 1}

      assert :ok = Dispatcher.dispatch(message)
      Process.sleep(50)
    end
  end

  describe "dispatch/1 with periodicity" do
    test "processes periodicity without errors" do
      periodicity = :daily

      assert :ok = Dispatcher.dispatch(periodicity)
      Process.sleep(50)
    end
  end

  describe "send_email/1" do
    test "handles email delivery" do
      email = %Bamboo.Email{
        from: "test@example.com",
        to: "recipient@example.com",
        subject: "Test",
        text_body: "Test message"
      }

      assert :ok = Dispatcher.send_email(email)
    end
  end
end
