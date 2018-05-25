use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :td_audit, TdAuditWeb.Endpoint,
  secret_key_base: "swAwdqbWSItB0JLIrd/xoN+5T3zrkZVPaJyE13GlE1sBC8IDZbmpVmN9KjikWj69"

# Configure your database
config :td_audit, TdAudit.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "td_audit_prod",
  pool_size: 15

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

config :td_audit, queue: TdAudit.Queue
