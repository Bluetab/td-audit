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

config :td_audit, TdAudit.Auth.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

config :td_cache, redis_host: System.fetch_env!("REDIS_HOST")
config :td_audit, host_name: System.get_env("WEB_HOST")
config :td_audit, TdAudit.Broadway,
  consumer_id: System.fetch_env!("HOSTNAME"),
  redis_host: System.fetch_env!("REDIS_HOST")
