defmodule TdAudit.Application do
  @moduledoc false

  use Application

  alias TdAudit.Repo
  alias TdAuditWeb.Endpoint

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    notifications_worker = %{
      id: TdAudit.NotificationLoader,
      start: {TdAudit.NotificationLoader, :start_link, []}
    }

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Repo, []),
      # Start the endpoint when the application starts
      supervisor(Endpoint, []),
      # Start your own worker by calling: TdAudit.Worker.start_link(arg1, arg2, arg3)
      # worker(TdAudit.Worker, [arg1, arg2, arg3]),
      supervisor(Exq, []),
      %{
        id: TdAudit.CustomSupervisor,
        start:
          {TdAudit.CustomSupervisor, :start_link,
           [%{children: [notifications_worker], strategy: :one_for_one}]},
        type: :supervisor
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TdAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
