defmodule TdAudit.Notifications.Loader do
  @moduledoc """
  This module saves those subscriptions that should be
  sent automatically
  """

  use GenServer

  alias TdAudit.Notifications.Dispatcher
  alias TdAudit.NotificationsSystem

  require Logger

  @notification_load_frequency Application.get_env(
                                 :td_audit,
                                 :notification_load_frequency
                               )[:events]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_work(:comment_created)
    schedule_work(:failed_rule_results)
    {:ok, state}
  end

  @impl true
  def handle_info(:failed_rule_results, state) do
    execute_notifications_dispatcher_for_event(%{event: "failed_rule_results"})
    schedule_work(:failed_rule_results)
    {:noreply, state}
  end

  @impl true
  def handle_info(:comment_created, state) do
    execute_notifications_dispatcher_for_event(%{event: "comment_created"})
    schedule_work(:comment_created)
    {:noreply, state}
  end

  defp schedule_work(:comment_created) do
    span = Map.get(@notification_load_frequency, :comment_created)
    Process.send_after(self(), :comment_created, span)
  end

  defp schedule_work(:failed_rule_results) do
    span = Map.get(@notification_load_frequency, :failed_rule_results)
    Process.send_after(self(), :failed_rule_results, span)
  end

  defp execute_notifications_dispatcher_for_event(%{event: "comment_created"} = params) do
    params
    |> active_configuration?()
    |> dispatch_notification(%{event: "comment_created"})
  end

  defp execute_notifications_dispatcher_for_event(%{event: "failed_rule_results"} = params) do
    params
    |> active_configuration?()
    |> dispatch_notification(%{event: "failed_rule_results"})
  end

  defp dispatch_notification(true, %{event: "comment_created"}) do
    Dispatcher.dispatch_notification(
      {:dispatch_on_comment_creation, "comment_created"}
    )
  end

  defp dispatch_notification(true, %{event: "failed_rule_results"}) do
    Dispatcher.dispatch_notification(
      {:dispatch_on_failed_results, "failed_rule_results"}
    )
  end

  defp dispatch_notification(_, %{event: event}) do
    Logger.info("Inactive configuration for event: #{event}")
  end

  defp active_configuration?(params) do
    case NotificationsSystem.get_configuration_by_filter(params) do
      nil ->
        nil

      configuration ->
        configuration
        |> Map.fetch!(:settings)
        |> Map.fetch!("generate_notification")
        |> Map.fetch!("active")
    end
  end
end
