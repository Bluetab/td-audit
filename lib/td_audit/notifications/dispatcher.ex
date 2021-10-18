defmodule TdAudit.Notifications.Dispatcher do
  @moduledoc """
  GenServer module to manage dispatching of notifications.
  """

  use GenServer

  alias TdAudit.Notifications
  alias TdAudit.Notifications.Mailer

  require Logger

  ## Public API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :unused, name: __MODULE__)
  end

  def dispatch(%{} = message) do
    GenServer.cast(__MODULE__, {:share, message})
  end

  def dispatch(periodicity) do
    GenServer.cast(__MODULE__, periodicity)
  end

  def send_email(email) do
    case Mailer.deliver_now(email, response: true) do
      {:ok, response} ->
        Logger.info("Email sent: Obtained #{inspect(response)} from server")

      {:ok, _email, response} ->
        Logger.info("Email sent: Obtained #{inspect(response)} from server")
        Logger.info("Email sent  from server")

      {:error, error} ->
        Logger.error("Error: #{error}")
    end
  end

  ## GenServer callbacks

  @impl GenServer
  def init(_init_arg) do
    {:ok, :no_state}
  end

  @impl GenServer
  def handle_cast({:share, message}, state) do
    Logger.debug("Triggering message...")

    message
    |> Notifications.share()
    |> case do
      {:ok, email} -> send_email(email)
      {:error, _} -> :ignore
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(periodicity, state) do
    Logger.debug("Triggering #{periodicity} notifications...")

    with {:ok, _} <- Notifications.create(periodicity: periodicity),
         {:ok, %{emails: emails}} when emails != [] <- Notifications.send_pending() do
      Enum.each(emails, &send_email/1)
    end

    {:noreply, state}
  end
end
