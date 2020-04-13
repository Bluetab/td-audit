defmodule TdAudit.QueueMock do
  @moduledoc false

  alias TdAudit.Audit.Event

  def enqueue(_queue, worker, params) do
    status = worker.perform(params)

    case status do
      {:ok, %Event{} = event} -> {:ok, event.id}
      {:error, _} -> status
    end
  end
end
