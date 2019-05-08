use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :td_audit, TdAuditWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :td_audit, TdAudit.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "td_audit_test",
  hostname: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

config :td_audit, queue: TdAudit.QueueMock

config :td_audit, :auth_service, api_service: TdAuditWeb.ApiServices.MockTdAuthService,
  auth_host: "localhost",
  auth_port: "4001",
  auth_domain: ""

config :td_audit, :elasticsearch,
  search_service: TdAudit.Search.MockSearch,
  es_host: "elastic",
  es_port: 9200,
  type_name: "doc"

config :td_audit, email_account: "email@foo.bar"

config :td_audit, TdAudit.Smtp.Mailer,
  adapter: Bamboo.TestAdapter

config :td_audit, user_cache: TdPerms.UserCacheMock
config :td_audit, bc_cache: TdPerms.MockBusinessConceptCache

config :td_audit, notification_loader_on_startup: false

config :td_perms, redis_host: "redis"
config :td_audit, host_name: "http://localhost:8080"

config :exq,
  host: "redis"
