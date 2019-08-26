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
                               )[:events]

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  @impl true
  def init(state) do
    schedule_work(:create_comment)
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
  def handle_info(:create_comment, state) do
    execute_notifications_dispatcher_for_event(%{event: "create_comment"})
    schedule_work(:create_comment)
    {:noreply, state}
  end

  defp schedule_work(:create_comment) do
    span = Map.get(@notification_load_frequency, :create_comment)
    Process.send_after(self(), :create_comment, span)
  end

  defp schedule_work(:failed_rule_results) do
    span = Map.get(@notification_load_frequency, :failed_rule_results)
    Process.send_after(self(), :failed_rule_results, span)
  end

  defp execute_notifications_dispatcher_for_event(%{event: "create_comment"} = params) do
    params
    |> active_configuration?()
    |> dispatch_notification(%{event: "create_comment"})
  end

  defp execute_notifications_dispatcher_for_event(%{event: "failed_rule_results"} = params) do
    params
    |> active_configuration?()
    |> dispatch_notification(%{event: "failed_rule_results"})
  end

  defp dispatch_notification(true, %{event: "create_comment"}) do
    NotificationDispatcher.dispatch_notification(
      {:dispatch_on_comment_creation, "create_comment"}
    )
  end

  defp dispatch_notification(true, %{event: "failed_rule_results"}) do
    NotificationDispatcher.dispatch_notification(
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
