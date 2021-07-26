use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :td_audit, TdAuditWeb.Endpoint,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :td_audit, TdAudit.Repo,
  username: "postgres",
  password: "postgres",
  database: "td_audit_dev",
  hostname: "localhost",
  pool_size: 4

config :td_audit, TdAudit.Notifications.Mailer, adapter: Bamboo.LocalAdapter

config :td_cache, redis_host: "localhost"
config :td_audit, host_name: "http://localhost:8080"
