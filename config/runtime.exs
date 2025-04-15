import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/td_audit start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :td_audit, TdAuditWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :tzdata, :data_dir, System.get_env("TZ_DATA_DIR")

  config :tzdata,
         :autoupdate,
         System.get_env("TZ_AUTOUPDATE", "disabled") |> String.to_existing_atom()

  config :td_audit, :time_zone, System.get_env("TZ", "Etc/UTC")

  get_ssl_option = fn env_var, option_key ->
    if System.get_env("DB_SSL", "") |> String.downcase() == "true" do
      case System.get_env(env_var, "") do
        "" -> []
        "nil" -> []
        value -> [{option_key, value}]
      end
    else
      []
    end
  end

  optional_db_ssl_options_cacertfile = get_ssl_option.("DB_SSL_CACERTFILE", :cacertfile)
  optional_db_ssl_options_certfile = get_ssl_option.("DB_SSL_CLIENT_CERT", :certfile)
  optional_db_ssl_options_keyfile = get_ssl_option.("DB_SSL_CLIENT_KEY", :keyfile)

  config :td_audit, TdAudit.Repo,
    username: System.fetch_env!("DB_USER"),
    password: System.fetch_env!("DB_PASSWORD"),
    database: System.fetch_env!("DB_NAME"),
    hostname: System.fetch_env!("DB_HOST"),
    port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
    pool_size: System.get_env("DB_POOL_SIZE", "4") |> String.to_integer(),
    timeout: System.get_env("DB_TIMEOUT_MILLIS", "15000") |> String.to_integer(),
    ssl: System.get_env("DB_SSL", "") |> String.downcase() == "true",
    ssl_opts:
      [
        verify:
          System.get_env("DB_SSL_VERIFY", "verify_none") |> String.downcase() |> String.to_atom(),
        server_name_indication: System.get_env("DB_HOST") |> to_charlist(),
        versions: [
          System.get_env("DB_SSL_VERSION", "tlsv1.2") |> String.downcase() |> String.to_atom()
        ]
      ] ++
        optional_db_ssl_options_cacertfile ++
        optional_db_ssl_options_certfile ++
        optional_db_ssl_options_keyfile

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
        System.get_env(
          "NOTIFICATION_SUBJECT_RULE_RESULTS",
          "👓 Alert: Data quality issues detected"
        ),
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
end
