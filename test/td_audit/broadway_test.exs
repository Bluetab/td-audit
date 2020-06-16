defmodule TdAudit.BroadwayTest do
  use TdAudit.DataCase

  alias TdAudit.Audit.Event

  test "creates an event and sends an ack for a valid audit message" do
    payload = %{"foo" => "bar"}

    ref =
      Broadway.test_message(TdAudit.Broadway, %{
        event: "test_event",
        id: "1598765432100-0",
        payload: Jason.encode!(payload),
        resource_id: "12345",
        resource_type: "foo",
        service: "td_audit_test",
        stream: "audit:events",
        ts: "2006-01-02T15:04:05.999Z",
        user_id: "54321"
      })

    assert_receive {:ack, ^ref, [%{data: data}] = _successful_messages, [] = _failure_messages}
    assert {:ok, event} = data

    assert %Event{
             event: "test_event",
             payload: ^payload,
             resource_id: 12_345,
             resource_type: "foo",
             service: "td_audit_test",
             ts: ~U[2006-01-02 15:04:05.999000Z],
             user_id: 54_321
           } = event
  end

  test "sends an ack for an invalid message" do
    ref = Broadway.test_message(TdAudit.Broadway, :test)
    assert_receive {:ack, ^ref, [] = _successful_messages, [%{data: :test}] = _failure_messages}
  end
end
