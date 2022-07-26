# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
config :td_audit, :time_zone, System.get_env("TZ", "Etc/UTC")

# Environment
config :td_audit, :env, Mix.env()

# General application configuration
config :td_audit,
  ecto_repos: [TdAudit.Repo]

# Configures the endpoint
config :td_audit, TdAuditWeb.Endpoint,
  http: [port: 4007],
  url: [host: "localhost"],
  render_errors: [view: TdAuditWeb.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
# set EX_LOGGER_FORMAT environment variable to override Elixir's Logger format
# (without the 'end of line' character)
# EX_LOGGER_FORMAT='$date $time [$level] $message'
config :logger, :console,
  format:
    (System.get_env("EX_LOGGER_FORMAT") || "$date\T$time\Z [$level]$levelpad $metadata$message") <>
      "\n",
  level: :info,
  metadata: [:pid, :module],
  utc_log: true

# Configuration for Phoenix
config :phoenix, :json_library, Jason
config :phoenix_swagger, :json_library, Jason

config :td_audit, TdAudit.Auth.Guardian,
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  ttl: {1, :hours},
  secret_key: "SuperSecretTruedat"

config :td_audit, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [router: TdAuditWeb.Router]
  }

config :td_audit, concepts_path: "/concepts"
config :td_audit, rules_path: "/rules"

config :td_audit, TdAudit.Notifications.Mailer, adapter: Bamboo.SMTPAdapter

config :td_audit, TdAudit.Notifications.Email,
  sender: {"Truedat Notifications", "no-reply@truedat.io"},
  subjects: [
    comments: "🖋 Alert: New comments added",
    concepts: "🖋 Alert: New event in Business Glosary",
    default: "⚡ Alert: New notifications",
    grants: "👓 Alert: Grant notification",
    grant_approval: "👓 Alert: Grant request notification",
    implementations: "⚡ Alert: Implementation notification",
    ingests_pending: "📬 Alert: Data requests pending approval",
    notes: "👓 Alert: Changes in structure notes",
    relations: "👓 Alert: Relations changed",
    rule_results: "👓 Alert: Data quality results detected",
    rules: "⚡ Alert: Rule notification",
    sources: "⚡ Alert: Source notification",
    tags: "👓 Alert: Changes in tags"
  ],
  headers: [
    comments: "The following comments have been added:",
    concepts: "The following concepts have been changed:",
    default: "New notifications have been generated:",
    grants: "The following changes in grants have been detected over a structure:",
    grant_approval: "The following changes in grant requets have been detected",
    implementations: "The following changes in implementations have been detected",
    ingests_pending: "The following data requests require approval:",
    notes: "The following changes in notes have been detected over a structure:",
    relations: "The following relations have been deprecated due to the deletion of its target",
    rule_results: "The following data quality results have been detected:",
    rules: "The following changes in rules have been detected",
    sources: "The following status changes have been detected over origin",
    tags: "The following changes in tags have been detected over a structure:"
  ],
  footer: "This message was sent by Truedat"

config :td_audit, TdAudit.Broadway,
  producer_module: TdAudit.Redis.Producer,
  consumer_group: "td_audit",
  consumer_id: "local",
  stream: "audit:events",
  redis_host: "redis",
  port: 6379

config :td_audit, TdAudit.Scheduler,
  jobs: [
    [
      schedule: "@minutely",
      task: {TdAudit.Notifications.Dispatcher, :dispatch, ["minutely"]},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@hourly",
      task: {TdAudit.Notifications.Dispatcher, :dispatch, ["hourly"]},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@daily",
      task: {TdAudit.Notifications.Dispatcher, :dispatch, ["daily"]},
      run_strategy: Quantum.RunStrategy.Local
    ]
  ]

config :number, delimit: [delimiter: " ", separator: ",", precision: 0]
config :number, percentage: [delimiter: " ", separator: ",", precision: 2]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
