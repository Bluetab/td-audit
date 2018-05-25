defmodule TdAudit.SendEventWorker do
  @moduledoc false

  alias TdAudit.Audit

  def perform(event_params) do
    Audit.create_event(event_params)
  end
end
