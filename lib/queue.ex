defmodule TdAudit.Queue do
  @moduledoc false

  def enqueue(queue, worker, params) do
    Exq.enqueue(Exq, queue, worker, [params])
  end
end
