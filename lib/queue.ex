defmodule TdAuditQueue do
  def enqueue(queue, worker, params) do
    Exq.enqueue(Exq, queue, worker, [params])
  end
end
