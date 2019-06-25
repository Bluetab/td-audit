defmodule TdAudit.Mixfile do
  use Mix.Project

  def project do
    [
      app: :td_audit,
      version:
        case System.get_env("APP_VERSION") do
          nil -> "2.19.0-local"
          v -> v
        end,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext, :phoenix_swagger] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TdAudit.Application, []},
      extra_applications: [:logger, :bamboo, :bamboo_smtp, :runtime_tools, :td_cache]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:exq, "~> 0.13.2"},
      {:jason, "~> 1.0"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0", runtime: false},
      {:guardian, "~> 1.2.1"},
      {:httpoison, "~> 1.2.0"},
      {:phoenix_swagger, "~> 0.8.0"},
      {:ex_json_schema, "~> 0.5"},
      {:td_perms, git: "https://github.com/Bluetab/td-perms.git", tag: "2.16.3"},
      {:td_cache,
       git: "https://github.com/Bluetab/td-cache.git",
       ref: "f70607e8ada8a60103b7f1bbfe516152adec3489"},
      {:bamboo, "~> 1.1"},
      {:bamboo_smtp, "~> 1.6.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
