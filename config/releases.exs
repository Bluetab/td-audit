import Config

config :td_audit, TdAudit.Repo,
  username: System.fetch_env!("DB_USER"),
  password: System.fetch_env!("DB_PASSWORD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST"),
  pool_size: System.get_env("DB_POOL_SIZE", "4") |> String.to_integer()

# Configure smtp client
config :td_audit, email_account: System.get_env("SMTP_SENDER")

config :td_audit, TdAudit.Smtp.Mailer,
  server: System.get_env("SMTP_SERVER"),
  port: System.get_env("SMTP_PORT"),
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  tls: :always,
  ssl: false,
  retries: 3

# Configure Exq
config :exq,
  host: System.fetch_env!("REDIS_HOST"),
  namespace: System.fetch_env!("REDIS_NAMESPACE"),
  concurrency: 1000,
  queues: ["timeline"],
  max_retries: 25,
  dead_max_jobs: 10_000,
  # 180 days
  dead_timeout_in_seconds: 180 * 24 * 60 * 60,
  start_on_application: false

config :td_audit, TdAudit.Auth.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

config :td_cache, redis_host: System.fetch_env!("REDIS_HOST")
config :td_audit, host_name: System.get_env("WEB_HOST")
