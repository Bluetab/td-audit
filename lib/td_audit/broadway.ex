defmodule TdAudit.Broadway do
  @moduledoc """
  A `Broadway` module for ingesting audit events from a Redis stream.
  """

  use Broadway

  import Broadway.Message, only: [update_data: 2, failed: 2]

  alias Broadway.Message
  alias TdAudit.Audit
  alias TdAudit.Redis.Acknowledger

  require Logger

  def start_link(opts) do
    producer = {_module, _opts} = Keyword.pop!(opts, :producer_module)
    acknowledger = Acknowledger.spec(opts)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: producer,
        transformer: {__MODULE__, :transform, acknowledger: acknowledger}
        # concurrency: 1,
        # rate_limiting: [allowed_messages: 100, interval: 1_000]
      ],
      processors: [
        default: [concurrency: 1]
      ],
      batchers: [
        default: [batch_size: 100, batch_timeout: 100]
      ]
    )
  end

  @impl Broadway
  def handle_message(_processor, %{data: %{}} = message, _context) do
    message
    |> update_data(fn data -> Audit.create_event(data) end)
    |> handle_failure()
  end

  @impl Broadway
  def handle_message(_processor, %{data: data} = message, _context) do
    unless data == :test do
      Logger.warn("Invalid message #{inspect(data)}")
    end

    failed(message, :invalid)
  end

  defp handle_failure(%Broadway.Message{data: data} = message) do
    case data do
      {:ok, _} ->
        message

      {:error, changeset} ->
        failed(message, changeset)

      _ ->
        failed(message, :invalid)
    end
  end

  @impl Broadway
  def handle_batch(_batcher, messages, _batch_info, _context) do
    messages
  end

  @doc "Transform an event into a Broadway Message"
  def transform(%{id: id} = data, opts) do
    %Message{
      data: data,
      acknowledger: opts[:acknowledger],
      metadata: %{id: id}
    }
  end
end
