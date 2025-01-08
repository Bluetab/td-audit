defmodule TdAudit.Redis.Acknowledger do
  @moduledoc """
  A `Broadway.Acknowledger` for a Redis stream consumer group.
  """

  @behaviour Broadway.Acknowledger

  alias TdCache.Redix.Stream

  require Logger

  @doc """
  Returns a specification for the acknowledger. For Redis streams, we use
  the `stream` and `consumer_group` options to configure the consumer group.
  """
  def spec(opts) do
    stream = Keyword.fetch!(opts, :stream)
    group = Keyword.get(opts, :consumer_group, "default")
    {__MODULE__, {stream, group}, []}
  end

  ## Broadway.Acknowledger callbacks

  @impl Broadway.Acknowledger
  def ack({stream, group}, succeeded, failed) do
    # Log failures. Note that Redis will leave unacknowledged entries in the
    # Pending Entry List (PEL), so nothing else needs to be done.
    case length(failed) do
      0 ->
        :ok

      n ->
        Logger.warning("Ignored #{n} failed messages")
    end

    # Acknowledge successfully processed messages, if any.
    case length(succeeded) do
      0 ->
        :ok

      _ ->
        ids = Enum.map(succeeded, fn %{metadata: %{id: id}} -> id end)
        {:ok, count} = Stream.ack(:redix, stream, group, ids)
        Logger.info("Acknowledged #{count} successful messages")
    end
  end
end
