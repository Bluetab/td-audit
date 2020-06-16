defmodule TdAudit.Redis.AcknowledgerTest do
  use ExUnit.Case, async: true

  alias TdAudit.Redis.Acknowledger
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream "audit:events:test:ack"
  @group "my_group"
  @consumer "consumer_id"

  describe "spec/1" do
    test "obtains acknowledger spec from options" do
      opts = Application.get_env(:td_audit, TdAudit.Broadway)
      assert Acknowledger.spec(opts) == {Acknowledger, {opts[:stream], opts[:consumer_group]}, []}
    end
  end

  describe "ack/3" do
    setup do
      on_exit(fn -> Redix.del!(@stream) end)

      {:ok, _} = Stream.create_stream(@stream)
      {:ok, _} = Stream.create_consumer_group(@stream, @group)
      {:ok, event_id} = Redix.command(["XADD", @stream, "*", "foo", "bar"])
      {:ok, _} = Stream.read_group(:redix, @stream, @group, @consumer, count: 1)

      [event_id: event_id]
    end

    test "acknowledges successfully processed messages", %{event_id: event_id} do
      assert [1, ^event_id, ^event_id, [[@consumer, "1"]]] =
               Redix.command!(["XPENDING", @stream, @group])

      assert Acknowledger.ack({@stream, @group}, [%{metadata: %{id: event_id}}], []) == :ok
      assert [0, nil, nil, nil] = Redix.command!(["XPENDING", @stream, @group])
    end
  end
end
