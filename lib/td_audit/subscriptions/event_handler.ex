defmodule TdAudit.Subscriptions.EventHandler do
  @moduledoc """
  Processes events which affect subscriptions.
  """

  use GenServer

  alias TdAudit.Subscriptions.EventProcessor

  ## Client API

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def after_insert(event) do
    GenServer.cast(__MODULE__, event)
    {:ok, event}
  end

  ## GenServer callbacks

  @impl GenServer
  def init(_init_arg) do
    {:ok, :unused}
  end

  @impl GenServer
  def handle_cast(event, state) do
    EventProcessor.process_event(event)
    {:noreply, state}
  end
end
