defmodule TdAudit.QueueMock do
  @moduledoc false

  def enqueue(_queue, worker, params) do
    worker.perform(params)
  end
end
