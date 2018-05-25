defmodule TdAudit.QueueMock do
  def enqueue(_queue, worker, params) do
    worker.perform(params)
  end
end
