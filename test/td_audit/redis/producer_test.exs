defmodule TdAudit.Redis.ProducerTest do
  use ExUnit.Case, async: true

  alias TdAudit.Redis.Producer
  alias TdCache.Redix

  @stream "audit:events:test:producer"

  setup do
    on_exit(fn -> Redix.del!(@stream) end)

    opts =
      :td_audit
      |> Application.fetch_env!(TdAudit.Broadway)
      |> Keyword.put(:stream, @stream)

    {:ok, event_id} = Redix.command(["XADD", @stream, "*", "foo", "bar"])
    {:ok, _pid} = GenStage.start_link(Producer, opts, name: Producer)

    [event_id: event_id]
  end

  describe "TdAudit.Redis.Producer" do
    test "produces events from redis", %{event_id: event_id} do
      stream = GenStage.stream([{Producer, max_demand: 1}])
      assert [event] = Enum.take(stream, 1)
      assert %{id: ^event_id, foo: "bar"} = event
    end
  end
end
