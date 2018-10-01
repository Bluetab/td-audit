defmodule TdAudit.Mixfile do
  use Mix.Project
  alias Mix.Tasks.Phx.Swagger.Generate, as: PhxSwaggerGenerate

  def project do
    [
      app: :td_audit,
      version: "2.6.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
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
      extra_applications: [:logger, :runtime_tools, :exq_ui]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.3"},
      {:phoenix_pubsub, "~> 1.0.2"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:exq, "~> 0.11.0"},
      {:exq_ui, "~> 0.9.0"},
      {:credo, "~> 0.9.3", only: [:dev, :test], runtime: false},
      {:edeliver, "~> 1.5.0"},
      {:distillery, "~> 1.0.0", warn_missing: false},
      {:guardian, "~> 1.1.0"},
      {:httpoison, "~> 1.2.0"},
      {:phoenix_swagger, "~> 0.7.0"},
      {:ex_json_schema, "~> 0.5"},
      {:td_perms, git: "https://github.com/Bluetab/td-perms.git", tag: "v0.3.5"}
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
      "test": ["ecto.create --quiet", "ecto.migrate", "test"],
      "compile": ["compile", &pxh_swagger_generate/1]
    ]
  end

  defp pxh_swagger_generate(_) do
    if Mix.env in [:dev, :prod] do
      PhxSwaggerGenerate.run(["priv/static/swagger.json"])
    end
  end
end
