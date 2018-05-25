defmodule TdAudit.ReleaseTasks do
  @moduledoc false

  alias Ecto.Migrator
  alias TdAudit.Repo

  @start_apps [
      :postgrex,
      :ecto
    ]

    @myapps [
      :td_audit
    ]

    @repos [
      Repo
    ]

    def seed do
      #IO.puts "Loading TdAudit.."
      # Load the code for TdAudit, but don't start it
      :ok = Application.load(:td_audit)

      #IO.puts "Starting dependencies.."
      # Start apps necessary for executing migrations
      Enum.each(@start_apps, &Application.ensure_all_started/1)

      # Start the Repo(s) for TdAudit
      #IO.puts "Starting repos.."
      Enum.each(@repos, &(&1.start_link(pool_size: 1)))

      # Run migrations
      Enum.each(@myapps, &run_migrations_for/1)

      # Run the seed script if it exists
      seed_script = Path.join([priv_dir(:td_audit), "repo", "seeds.exs"])
      if File.exists?(seed_script) do
        IO.puts "Running seed script.."
        Code.eval_file(seed_script)
      end

      # Signal shutdown
      #IO.puts "Success!"
      :init.stop()
    end

    def priv_dir(app), do: "#{:code.priv_dir(app)}"

    defp run_migrations_for(app) do
      IO.puts "Running migrations for #{app}"
      Migrator.run(TdAudit.Repo, migrations_path(app), :up, all: true)
    end

    defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
    #defp seed_path(app), do: Path.join([priv_dir(app), "repo", "seeds.exs"])
end
