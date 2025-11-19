defmodule TdAudit.ApplicationTest do
  use ExUnit.Case

  alias TdAudit.Application

  describe "start/2" do
    test "returns error when already started" do
      # Application is already started in test environment
      assert {:error, {:already_started, _pid}} = Application.start(:normal, [])
    end
  end

  describe "config_change/3" do
    test "calls endpoint config_change with valid parameters" do
      # Test with valid parameters that won't cause errors
      :ok = Application.config_change([], [], [])
    end
  end
end
