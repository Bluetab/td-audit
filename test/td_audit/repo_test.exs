defmodule TdAudit.RepoTest do
  use ExUnit.Case

  alias TdAudit.Repo

  describe "init/2" do
    test "loads database_url from environment variable" do
      System.put_env("DATABASE_URL", "ecto://user:pass@host/database_test")
      {:ok, opts} = Repo.init(__MODULE__, [])
      assert opts[:url] == "ecto://user:pass@host/database_test"
      System.delete_env("DATABASE_URL")
    end

    test "returns nil for database_url if not set" do
      System.delete_env("DATABASE_URL")
      {:ok, opts} = Repo.init(__MODULE__, [])
      assert is_nil(opts[:url])
    end

    test "preserves other options" do
      System.put_env("DATABASE_URL", "ecto://user:pass@host/database_test")
      {:ok, opts} = Repo.init(__MODULE__, pool_size: 10, timeout: 5000)
      assert opts[:url] == "ecto://user:pass@host/database_test"
      assert opts[:pool_size] == 10
      assert opts[:timeout] == 5000
      System.delete_env("DATABASE_URL")
    end
  end
end
