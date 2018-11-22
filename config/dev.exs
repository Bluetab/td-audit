use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :td_audit, TdAuditWeb.Endpoint,
  http: [port: 4007],
  url: [host: "localhost", port: 4007],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :td_audit, TdAudit.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "td_audit_dev",
  hostname: "localhost",
  pool_size: 10

config :td_audit, :auth_service, api_service: TdAuditWeb.ApiServices.HttpTdAuthService,
  auth_host: "localhost",
  auth_port: "4001",
  auth_domain: ""

config :td_audit, :elasticsearch,
  search_service: TdAudit.Search,
  es_host: "localhost",
  es_port: 9200,
  type_name: "doc"

config :td_audit, email_account: "no-reply@example.com"

config :td_audit, TdAudit.Smtp.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.example.com",
  port: 587,
  username: "auth_user",
  password: "secret-pasword",
  tls: :always,
  ssl: false,
  retries: 3

config :td_audit, queue: TdAudit.Queue

config :td_perms, redis_uri: "redis://localhost"
config :td_audit, host_name: "http://localhost:8080"
