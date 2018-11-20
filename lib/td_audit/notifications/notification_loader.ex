defmodule TdAudit.NotificationLoader do
 @moduledoc """
 This module saves those subscriptions that should be
 sent automatically
 """
 use GenServer
 require Logger
 alias TdAudit.NotificationDispatcher
 alias TdAudit.NotificationsSystem

@notification_load_frequency Application.get_env(
  :td_audit,
  :notification_load_frequency
)

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

 @impl true
 def init(state) do
  schedule_work()
  {:ok, state}
 end

 @impl true
 def handle_info(:work, state) do
  execute_notifications_dispatcher_for_event(%{"event": "create_comment"})
  schedule_work()
  {:noreply, state}
 end

 defp schedule_work do
  Process.send_after(self(), :work, @notification_load_frequency)
 end

 defp execute_notifications_dispatcher_for_event(%{"event": "create_comment"} = params) do
  active =
    case NotificationsSystem.get_configuration_by_filter(params) do
      nil -> nil
      configuration ->
        configuration
          |> Map.fetch!(:configuration)
          |> Map.fetch!("generate_notification")
          |> Map.fetch!("active")
    end

  dispatch_notification(active, %{"event": "create_comment"})
 end

 defp dispatch_notification(true, %{"event": "create_comment"}) do
  NotificationDispatcher.dispatch_notification({:dispatch_on_comment_creation, "create_comment"})
 end

 defp dispatch_notification(_, %{"event": "create_comment"}) do
  Logger.info(
      "Inactive configuration for event create_comment"
    )
 end
end
