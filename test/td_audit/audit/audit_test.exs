defmodule TdAudit.AuditTest do
  use TdAudit.DataCase

  alias TdAudit.Audit

  describe "events" do
    alias TdAudit.Audit.Event

    @valid_attrs %{event: "some event", payload: %{}, resource_id: 42, resource_type: "some resource_type", service: "some service", ts: "2010-04-17 14:00:00.000000Z", user_id: 42, user_name: "some name"}
    @update_attrs %{event: "some updated event", payload: %{}, resource_id: 43, resource_type: "some updated resource_type", service: "some updated service", ts: "2011-05-18 15:01:01.000000Z", user_id: 43, user_name: "some updated name"}
    @invalid_attrs %{event: nil, payload: nil, resource_id: nil, resource_type: nil, service: nil, ts: nil, user_id: nil, user_name: nil}

    def event_fixture(attrs \\ %{}) do
      {:ok, event} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Audit.create_event()

      event
    end

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Audit.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Audit.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      assert {:ok, %Event{} = event} = Audit.create_event(@valid_attrs)
      assert event.event == "some event"
      assert event.payload == %{}
      assert event.resource_id == 42
      assert event.resource_type == "some resource_type"
      assert event.service == "some service"
      assert event.ts == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert event.user_id == 42
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Audit.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      assert {:ok, event} = Audit.update_event(event, @update_attrs)
      assert %Event{} = event
      assert event.event == "some updated event"
      assert event.payload == %{}
      assert event.resource_id == 43
      assert event.resource_type == "some updated resource_type"
      assert event.service == "some updated service"
      assert event.ts == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert event.user_id == 43
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Audit.update_event(event, @invalid_attrs)
      assert event == Audit.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Audit.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Audit.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Audit.change_event(event)
    end
  end
end
