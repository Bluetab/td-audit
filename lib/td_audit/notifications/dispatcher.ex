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

  def dispatch(periodicity) do
    GenServer.call(__MODULE__, periodicity)
  end

  ## GenServer callbacks

  @impl GenServer
  def init(_init_arg) do
    {:ok, :no_state}
  end

  def send_email(email) do
    response = Mailer.deliver_now(email, response: true)
    Logger.info("Obtained #{response} from deliver function")
  end

  @impl GenServer
  def handle_call(periodicity, _from, state) do
    Logger.debug("Triggering #{periodicity} notifications...")

    # TO-DO: send emails sequentially
    with {:ok, _} <- Notifications.create(periodicity: periodicity),
         {:ok, %{emails: emails}} when emails != [] <- Notifications.send_pending() do
      Enum.each(emails, &send_email/1)
      {:reply, :ok, state}
    else
      {:ok, _} -> {:reply, :ok, state}
      {:error, failed_operation, _value, _changes} -> {:reply, {:error, failed_operation}, state}
      error -> {:reply, error, state}
    end
  end
end
