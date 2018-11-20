# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :td_audit,
  ecto_repos: [TdAudit.Repo]

# Configures the endpoint
config :td_audit, TdAuditWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "VtmbTFfMSsQ9Q6w56ZSIwNbyyxoAfK4DTe647m8H0kTn5rG/EQpTbHNLnCJQswtL",
  render_errors: [view: TdAuditWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: TdAudit.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

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

config :td_audit, TdAudit.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  ttl: { 1, :hours },
  secret_key: "SuperSecretTruedat"

config :td_audit, :auth_service,
  protocol: "http",
  users_path: "/api/users/",
  sessions_path: "/api/sessions/"

config :td_audit, notification_load_frequency: 60_000

config :td_audit, :phoenix_swagger,
       swagger_files: %{
         "priv/static/swagger.json" => [router: TdAuditWeb.Router]
       }

config :td_audit, permission_resolver: TdPerms.Permissions

config :td_audit, user_cache: TdPerms.UserCache

config :td_audit, business_concept_cache: TdPerms.BusinessConceptCache

config :td_perms, permissions: [
  :is_admin,
  :create_acl_entry,
  :update_acl_entry,
  :delete_acl_entry,
  :create_domain,
  :update_domain,
  :delete_domain,
  :view_domain,
  :create_business_concept,
  :create_data_structure,
  :update_business_concept,
  :update_data_structure,
  :send_business_concept_for_approval,
  :delete_business_concept,
  :delete_data_structure,
  :publish_business_concept,
  :reject_business_concept,
  :deprecate_business_concept,
  :manage_business_concept_alias,
  :view_data_structure,
  :view_draft_business_concepts,
  :view_approval_pending_business_concepts,
  :view_published_business_concepts,
  :view_versioned_business_concepts,
  :view_rejected_business_concepts,
  :view_deprecated_business_concepts,
  :manage_business_concept_links,
  :manage_quality_rule,
  :manage_confidential_business_concepts
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
