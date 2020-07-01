defmodule TdAudit.Application do
  @moduledoc false

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    env = Application.get_env(:td_audit, :env)

    children =
      [
        TdAudit.Repo,
        TdAuditWeb.Endpoint
      ] ++ children(env)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TdAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TdAuditWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp children(:test), do: [
    {TdAudit.Broadway, broadway_config()}
  ]

  defp children(_env) do
    [
      {TdAudit.Broadway, broadway_config()},
      TdAudit.Scheduler,
      TdAudit.Notifications.Dispatcher
    ]
  end

  defp broadway_config do
    Application.get_env(:td_audit, TdAudit.Broadway)
  end
end
