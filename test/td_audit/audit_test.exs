defmodule TdAudit.AuditTest do
  @moduledoc """
  Audit testing module
  """
  use TdAudit.DataCase

  alias TdAudit.Audit
  alias TdAudit.Audit.Event

  @valid_attrs %{
    event: "some event",
    payload: %{},
    resource_id: 42,
    resource_type: "some resource_type",
    service: "some service",
    ts: "2010-04-17 14:00:00Z",
    user_id: 42,
    user_name: "some name"
  }
  @valid_attrs_new_type_same_id %{
    event: "some event with new type",
    payload: %{},
    resource_id: 43,
    resource_type: "some new resource_type",
    service: "some updated service",
    ts: "2011-05-18 15:01:01Z",
    user_id: 43,
    user_name: "some updated name"
  }
  @valid_attrs_new_type_diff_id %{
    event: "some event with new type",
    payload: %{},
    resource_id: 42,
    resource_type: "some new resource_type",
    service: "some service",
    ts: "2010-04-17 14:00:00Z",
    user_id: 42,
    user_name: "some name"
  }
  @update_attrs %{
    event: "some updated event",
    payload: %{},
    resource_id: 43,
    resource_type: "some updated resource_type",
    service: "some updated service",
    ts: "2011-05-18 15:01:01Z",
    user_id: 43,
    user_name: "some updated name"
  }
  @invalid_attrs %{
    event: nil,
    payload: nil,
    resource_id: nil,
    resource_type: nil,
    service: nil,
    ts: nil,
    user_id: nil,
    user_name: nil
  }

  describe "list_events/0" do
    test "returns all events" do
      %{id: id} = insert(:event)
      assert [%{id: ^id}] = Audit.list_events()
    end
  end

  describe "list_events/1" do
    test "returns all events filtered by resource_id" do
      %{id: id} = insert(:event)
      insert(:event, @update_attrs)
      assert [%{id: ^id}] = Audit.list_events(%{"resource_id" => 42})
    end

    test "returns all events filtered by a payload attribute" do
      insert(:event)
      %{id: id1} = insert(:event, payload: %{"subscriber" => "mymail@foo.com"})
      %{id: id2} = insert(:event, payload: %{"subscriber" => "mymail@foo.com"})
      insert(:event, payload: %{"subscriber" => "notmymail@foo.com"})

      assert [%{id: ^id1}, %{id: ^id2}] =
               %{payload: %{subscriber: "mymail@foo.com"}}
               |> Audit.list_events()
               |> Enum.sort_by(& &1.id)
    end

    test "returns all events filtered by resource_type" do
      insert(:event)
      %{id: id} = insert(:event, @update_attrs)

      assert [%{id: ^id}] = Audit.list_events(%{"resource_type" => "some updated resource_type"})
    end

    test "returns all events filtered by resource_type and resource_id" do
      insert(:event, @update_attrs)
      insert(:event, @valid_attrs_new_type_diff_id)
      %{id: id} = insert(:event, @valid_attrs_new_type_same_id)

      assert [%{id: ^id}] =
               Audit.list_events(%{
                 "resource_id" => 43,
                 "resource_type" => "some new resource_type"
               })
    end

    test "returns events filtered by list of values" do
      insert(:event)
      insert(:event, resource_type: "auth")
      %{id: edi1} = insert(:event, resource_type: "auth", event: "login_attempt")
      %{id: edi2} = insert(:event, resource_type: "auth", event: "login_success")

      assert [%{id: ^edi2}, %{id: ^edi1}] =
               Audit.list_events(%{
                 "event" => ["login_attempt", "login_success"],
                 "resource_type" => "auth"
               })
    end

    test "returns events filtered by inserted_at" do
      insert(:event)
      insert(:event, resource_type: "auth")

      %{id: edi1, inserted_at: inserted_at} =
        insert(:event, resource_type: "auth", event: "login_attempt")

      date = DateTime.add(inserted_at, 3600, :second)

      %{id: edi2} =
        insert(:event, resource_type: "auth", event: "login_success", inserted_at: date)

      assert [%{id: ^edi2}, %{id: ^edi1}] =
               Audit.list_events(%{
                 "event" => ["login_attempt", "login_success"],
                 "resource_type" => "auth",
                 "inserted_at" => %{"gte" => inserted_at}
               })

      assert [%{id: ^edi2}] =
               Audit.list_events(%{
                 "event" => ["login_attempt", "login_success"],
                 "resource_type" => "auth",
                 "inserted_at" => %{"gt" => inserted_at}
               })

      assert [%{id: ^edi2}, %{id: ^edi1}] =
               Audit.list_events(%{
                 "event" => ["login_attempt", "login_success"],
                 "resource_type" => "auth",
                 "inserted_at" => %{"lte" => date}
               })

      assert [%{id: ^edi1}] =
               Audit.list_events(%{
                 "event" => ["login_attempt", "login_success"],
                 "resource_type" => "auth",
                 "inserted_at" => %{"lt" => date}
               })
    end
  end

  describe "get_event!/1" do
    test "returns the event with given id" do
      %{id: id} = event = insert(:event)
      assert Audit.get_event!(id) == event
    end
  end

  describe "create_event/1" do
    test "with valid data creates a event" do
      assert {:ok, %Event{} = event} = Audit.create_event(@valid_attrs)
      assert event.event == "some event"
      assert event.payload == %{}
      assert event.resource_id == 42
      assert event.resource_type == "some resource_type"
      assert event.service == "some service"
      assert event.ts == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert event.user_id == 42
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Audit.create_event(@invalid_attrs)
    end
  end

  describe "max_event_id/1" do
    test "returns nil if there are no events" do
      assert Audit.max_event_id() == nil
    end

    test "returns the maximum id" do
      insert(:event, id: 123)
      insert(:event, id: 123_456_789)

      assert Audit.max_event_id() == 123_456_789
    end
  end
end
