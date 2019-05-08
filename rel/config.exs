use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"8PSOMww=e5*M5/y8)<55d&u?`X>kbR}vT?;M)qZ<)vApPiABh:}eSHq^Z8k,2=Yg"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"z{ckwDE>plPqKz7JcsQPQsmI(NGeQvdvIHOYI)`zu0qp*.&*_.6PU0OlogX?KZvK"
  set pre_start_hooks: "rel/hooks/pre_start"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :td_audit do
  set version: current_version(:td_audit)
  set applications: [
    :runtime_tools
  ]
  set commands: [
    migrate: "rel/commands/migrate.sh"
  ]
end

