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
  hostname: "localhost",
  pool_size: 10

#Configure elasticsearch
config :td_audit, :elasticsearch,
  search_service: TdAudit.Search,
  es_host: "localhost",
  es_port: 9200,
  type_name: "doc"

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

config :td_audit, TdAudit.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  ttl: { 1, :hours },
  secret_key: "SuperSecretTruedat"

config :td_audit, :auth_service, api_service: TdAuditWeb.ApiServices.HttpTdAuthService,
  auth_host: "localhost",
  auth_port: "4001",
  auth_domain: ""

config :td_perms, redis_uri: "redis://localhost"
