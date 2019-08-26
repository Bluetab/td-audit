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
  render_errors: [view: TdAuditWeb.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
# set EX_LOGGER_FORMAT environment variable to override Elixir's Logger format
# (without the 'end of line' character)
# EX_LOGGER_FORMAT='$date $time [$level] $message'
config :logger, :console,
  format: (System.get_env("EX_LOGGER_FORMAT") || "$time $metadata[$level] $message") <> "\n",
  metadata: [:request_id]

# Configuration for Phoenix
config :phoenix, :json_library, Jason

# Configure Exq
config :exq,
  host: "127.0.0.1",
  port: 6379,
  namespace: "exq",
  concurrency: 1000,
  queues: ["timeline"],
  max_retries: 25,
  dead_max_jobs: 10_000,
  # 6 months
  dead_timeout_in_seconds: 180 * 24 * 60 * 60,
  start_on_application: false

config :td_audit, TdAudit.Auth.Guardian,
  # optional
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  ttl: {1, :hours},
  secret_key: "SuperSecretTruedat"

config :td_audit, :notification_load_frequency,
  events: %{
    create_comment: 60_000,
    failed_rule_results: 86_400_000
  }

config :td_audit, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [router: TdAuditWeb.Router]
  }

config :td_audit, concepts_path: "/concepts"
config :td_audit, rules_path: "/rules"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
