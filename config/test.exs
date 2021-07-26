use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :td_audit, TdAuditWeb.Endpoint, server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :td_audit, TdAudit.Repo,
  username: "postgres",
  password: "postgres",
  database: "td_audit_test",
  hostname: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

config :td_audit, TdAudit.Notifications.Mailer, adapter: Bamboo.TestAdapter

config :td_audit, host_name: "http://localhost:8080"

config :td_cache, redis_host: "redis", port: 6380

config :td_audit, TdAudit.Broadway,
  producer_module: Broadway.DummyProducer,
  stream: "audit:events:test",
  redis_host: "redis",
  port: 6380
