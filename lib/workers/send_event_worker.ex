defmodule TdAudit.SendEventWorker do
  require Logger
  @moduledoc false

  alias TdAudit.Audit
  alias TdAudit.SearchEventProcessor
  alias TdAudit.SubscriptionEventProcessor

  def perform(event_params) do
    resp = create_event(event_params)
    process_event(event_params)
    resp
  end

  defp create_event(event_params) do
    Audit.create_event(event_params)
  end

  defp process_event(event_params) do
    SearchEventProcessor.process_event(event_params)
    SubscriptionEventProcessor.process_event(event_params)
  end
end
