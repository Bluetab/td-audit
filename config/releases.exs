import Config

config :td_audit, TdAudit.Repo,
  username: System.fetch_env!("DB_USER"),
  password: System.fetch_env!("DB_PASSWORD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST"),
  pool_size: System.get_env("DB_POOL_SIZE", "4") |> String.to_integer()

config :td_audit, TdAudit.Notifications.Mailer,
  server: System.get_env("SMTP_SERVER"),
  port: System.get_env("SMTP_PORT"),
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  tls: System.get_env("SMTP_TLS", "always") |> String.to_atom(),
  ssl: false,
  retries: 3

config :td_cache,
  redis_host: System.fetch_env!("REDIS_HOST"),
  port: System.get_env("REDIS_PORT", "6379") |> String.to_integer(),
  password: System.get_env("REDIS_PASSWORD")

config :td_audit, TdAudit.Auth.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")
config :td_audit, host_name: System.get_env("WEB_HOST")

config :k8s, clusters: %{default: %{}}

config :td_audit, TdAudit.Broadway,
  consumer_id: System.fetch_env!("HOSTNAME"),
  redis_host: System.fetch_env!("REDIS_HOST"),
  port: System.get_env("REDIS_PORT", "6379") |> String.to_integer(),
  password: System.get_env("REDIS_PASSWORD")

config :td_audit, TdAudit.Notifications.Email,
  sender:
    {System.get_env("SMTP_SENDER_NAME"), System.get_env("SMTP_SENDER", "no-reply@example.com")},
  subjects: [
    ingests_pending:
      System.get_env(
        "NOTIFICATION_SUBJECT_INGEST_PENDING",
        "📬 Alert: Data requests pending approval"
      ),
    rule_results:
      System.get_env("NOTIFICATION_SUBJECT_RULE_RESULTS", "👓 Alert: Data quality issues detected"),
    comments: System.get_env("NOTIFICATION_SUBJECT_COMMENTS", "🖋 Alert: New comments added"),
    default: System.get_env("NOTIFICATION_SUBJECT_DEFAULT", "⚡ Alert: New notifications")
  ],
  headers: [
    ingests_pending:
      System.get_env(
        "NOTIFICATION_HEADER_INGEST_PENDING",
        "The following data requests require approval:"
      ),
    rule_results:
      System.get_env(
        "NOTIFICATION_HEADER_RULE_RESULTS",
        "The following data quality issues have been detected:"
      ),
    comments:
      System.get_env("NOTIFICATION_HEADER_COMMENTS", "The following comments have been added:"),
    default:
      System.get_env("NOTIFICATION_HEADER_DEFAULT", "New notifications have been generated:")
  ],
  footer: System.get_env("NOTIFICATION_FOOTER", "This message was sent by Truedat")
