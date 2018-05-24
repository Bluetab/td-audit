# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :td_audit,
  ecto_repos: [TdAudit.Repo]

# Configures the endpoint
config :td_audit, TdAuditWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "VtmbTFfMSsQ9Q6w56ZSIwNbyyxoAfK4DTe647m8H0kTn5rG/EQpTbHNLnCJQswtL",
  render_errors: [view: TdAuditWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: TdAudit.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure Exq
config :exq,
  host: "127.0.0.1",
  port: 6379,
  namespace: "exq",
  concurrency: 1000,
  queues: ["timeline"],
  max_retries: 25,
  dead_max_jobs: 10_000,
  dead_timeout_in_seconds: 180 * 24 * 60 * 60, # 6 months
  start_on_application: false

# Configure Exq-Ui
config :exq_ui,
  web_port: 4047,
  web_namespace: "",
  server: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
