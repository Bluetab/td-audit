defmodule TdAudit.NotificationsSystemTest do
  use TdAudit.DataCase

  alias TdAudit.NotificationsSystem

  describe "notifications_system_configuration" do
    alias TdAudit.NotificationsSystem.Configuration

    @valid_attrs %{configuration: %{}, event: "some event"}
    @update_attrs %{configuration: %{}, event: "some updated event"}
    @invalid_attrs %{configuration: nil, event: nil}

    def configuration_fixture(attrs \\ %{}) do
      {:ok, configuration} =
        attrs
        |> Enum.into(@valid_attrs)
        |> NotificationsSystem.create_configuration()

      configuration
    end

    test "list_notifications_system_configuration/0 returns all notifications_system_configuration" do
      configuration = configuration_fixture()
      assert NotificationsSystem.list_notifications_system_configuration() == [configuration]
    end

    test "get_configuration!/1 returns the configuration with given id" do
      configuration = configuration_fixture()
      assert NotificationsSystem.get_configuration!(configuration.id) == configuration
    end

    test "create_configuration/1 with valid data creates a configuration" do
      assert {:ok, %Configuration{} = configuration} = NotificationsSystem.create_configuration(@valid_attrs)
      assert configuration.configuration == %{}
      assert configuration.event == "some event"
    end

    test "create_configuration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = NotificationsSystem.create_configuration(@invalid_attrs)
    end

    test "update_configuration/2 with valid data updates the configuration" do
      configuration = configuration_fixture()
      assert {:ok, configuration} = NotificationsSystem.update_configuration(configuration, @update_attrs)
      assert %Configuration{} = configuration
      assert configuration.configuration == %{}
      assert configuration.event == "some updated event"
    end

    test "update_configuration/2 with invalid data returns error changeset" do
      configuration = configuration_fixture()
      assert {:error, %Ecto.Changeset{}} = NotificationsSystem.update_configuration(configuration, @invalid_attrs)
      assert configuration == NotificationsSystem.get_configuration!(configuration.id)
    end

    test "delete_configuration/1 deletes the configuration" do
      configuration = configuration_fixture()
      assert {:ok, %Configuration{}} = NotificationsSystem.delete_configuration(configuration)
      assert_raise Ecto.NoResultsError, fn -> NotificationsSystem.get_configuration!(configuration.id) end
    end

    test "change_configuration/1 returns a configuration changeset" do
      configuration = configuration_fixture()
      assert %Ecto.Changeset{} = NotificationsSystem.change_configuration(configuration)
    end
  end
end
