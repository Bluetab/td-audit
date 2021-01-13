defmodule TdAudit.Redis.Producer do
  @moduledoc """
  A `GenStage` producer which produces audit messages from a Redis stream.
  """

  use GenStage

  alias TdCache.Redix.Stream

  require Logger

  @block 2_000
  @interval 0

  ## GenStage callbacks

  @impl GenStage
  def init(opts) do
    stream = Keyword.fetch!(opts, :stream)
    consumer_group = Keyword.get(opts, :consumer_group, "default")
    quiesce = Keyword.get(opts, :quiesce, 100)

    {:ok, _} = Stream.create_stream(stream)
    {:ok, _} = Stream.create_consumer_group(stream, consumer_group)
    Logger.info("Initialized producer for stream #{stream} group #{consumer_group}")

    state = %{
      consumer_group: consumer_group,
      consumer_id: Keyword.fetch!(opts, :consumer_id),
      stream: stream,
      block: Keyword.get(opts, :block, @block),
      interval: Keyword.get(opts, :interval, @interval),
      redix: start_redix(opts),
      demand: 0,
      timer: timer(quiesce)
    }

    {:producer, state}
  end

  @impl GenStage
  def handle_info(:poll, %{demand: 0} = state) do
    {:noreply, [], %{state | timer: timer(100)}}
  end

  @impl GenStage
  def handle_info(
        :poll,
        %{
          redix: redix,
          stream: stream,
          consumer_group: consumer_group,
          consumer_id: consumer_id,
          block: block,
          interval: interval,
          demand: demand
        } = state
      ) do
    {:ok, events} =
      Stream.read_group(redix, stream, consumer_group, consumer_id,
        count: demand,
        block: block,
        transform: true
      )

    state = %{
      state
      | demand: demand - Enum.count(events),
        timer: timer(interval)
    }

    {:noreply, events, state}
  end

  @impl GenStage
  def handle_demand(demand, %{demand: pending_demand} = state) when demand > 0 do
    state = %{state | demand: demand + pending_demand}
    {:noreply, [], state}
  end

  ## Private functions

  defp start_redix(opts) do
    # Starts a dedicated Redis connection for the consumer
    redis_host = Keyword.get(opts, :redis_host, "redis")
    port = Keyword.get(opts, :port, 6379)
    password = Keyword.get(opts, :password)
    {:ok, redix} = Redix.start_link(host: redis_host, port: port, password: password)
    redix
  end

  defp timer(millis) do
    Process.send_after(self(), :poll, millis)
  end
end
