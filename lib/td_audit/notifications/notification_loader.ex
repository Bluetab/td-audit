defmodule TdAudit.NotificationLoader do
 @moduledoc """
 This module saves those subscriptions that should be
 sent automatically
 """
 use GenServer
 alias TdAudit.NotificationDispatcher

 @notification_loader_on_startup Application.get_env(
  :td_audit,
  :notification_loader_on_startup
)

@notification_load_frequency Application.get_env(
  :td_audit,
  :notification_load_frequency
)

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

 @impl true
 def init(state) do
  if @notification_loader_on_startup, do: schedule_work()
  {:ok, state}
 end

 @impl true
 def handle_info(:work, state) do
  NotificationDispatcher.dispatch_notification({:dispatch_on_comment_creation, "create_comment"})
  schedule_work()
  {:reply, :ok, state}
 end

 defp schedule_work do
  Process.send_after(self(), :work, @notification_load_frequency)
 end
end
