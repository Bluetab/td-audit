defmodule TdAudit.Mixfile do
  use Mix.Project

  def project do
    [
      app: :td_audit,
      version:
        case System.get_env("APP_VERSION") do
          nil -> "7.5.1-local"
          v -> v
        end,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        td_audit: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          steps: [:assemble, &copy_bin_files/1, :tar]
        ]
      ]
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

  defp copy_bin_files(release) do
    File.cp_r("rel/bin", Path.join(release.path, "bin"))
    release
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_ecto, "~> 4.6.3"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.7"},
      {:ecto_sql, "~> 3.12.1"},
      {:postgrex, "~> 0.19.3"},
      {:jason, "~> 1.4.4"},
      {:guardian, "~> 2.3.2"},
      {:bamboo, "~> 2.2"},
      {:bamboo_phoenix, "~> 1.0"},
      {:bamboo_smtp, "~> 4.2.2"},
      {:tzdata, "~> 1.1.2"},
      {:td_cache, git: "https://github.com/Bluetab/td-cache.git", tag: "7.4.0"},
      {:td_df_lib, git: "https://github.com/Bluetab/td-df-lib.git", tag: "7.4.0"},
      {:gen_stage, "~> 1.2.1"},
      {:broadway, "~> 1.1"},
      {:quantum, "~> 3.5.3"},
      {:canada, "~> 2.0"},
      {:number, "~> 1.0.5"},
      {:assertions, "~> 0.20.1", only: :test},
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.5", only: :dev, runtime: false},
      {:ex_machina, "~> 2.8", only: :test},
      {:floki, "~> 0.37", only: :test},
      {:sobelow, "~> 0.13", only: [:dev, :test]}
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
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
