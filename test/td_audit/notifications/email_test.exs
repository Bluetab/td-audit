defmodule TdAudit.Notifications.EmailTest do
  @moduledoc """
  Audit testing module for Email
  """
  use TdAudit.DataCase

  alias TdAudit.EmailParser
  alias TdAudit.Notifications.Email

  describe "create/1" do
    test "renders single structure note field notification" do
      %{id: user_id} = CacheHelpers.put_user()
      %{id: domain_id, name: domain_name} = CacheHelpers.put_domain()
      structure_id = System.unique_integer([:positive])

      payload =
        string_params_for(
          :payload,
          data_structure_id: structure_id,
          field_parent_id: 12_345,
          domain_ids: [domain_id],
          resource: %{
            name: "child",
            path: ["grampa", "parent"]
          }
        )

      events = [
        build(:event,
          event: "structure_note_updated",
          payload: payload,
          resource_type: "data_structure_note"
        )
      ]

      [{link, title, events}] =
        :notification
        |> insert(events: events, recipient_ids: [user_id])
        |> Email.create()
        |> then(fn {:ok, %{html_body: html_body}} -> html_body end)
        |> Floki.parse_document!()
        |> EmailParser.parse_layout()
        |> EmailParser.parse_events()

      assert link =~ ~r|.*/structures/#{structure_id}/notes|
      assert title == "grampa > parent > child"

      assert [
               {"Evento:", "Structure note updated"},
               {"Dominio:", ^domain_name}
             ] = events
    end

    test "renders multiple structure note field notification with same parent" do
      %{id: user_id} = CacheHelpers.put_user()
      %{id: domain_id, name: domain_name} = CacheHelpers.put_domain()
      field_parent_id = System.unique_integer([:positive])
      structure_id_1 = System.unique_integer([:positive])
      structure_id_2 = System.unique_integer([:positive])

      payload_1 =
        string_params_for(
          :payload,
          data_structure_id: structure_id_1,
          field_parent_id: field_parent_id,
          domain_ids: [domain_id],
          resource: %{
            name: "child1",
            path: ["grampa", "parent"]
          }
        )

      payload_2 =
        string_params_for(
          :payload,
          data_structure_id: structure_id_2,
          field_parent_id: field_parent_id,
          domain_ids: [domain_id],
          resource: %{
            name: "child2",
            path: ["grampa", "parent"]
          }
        )

      events = [
        build(:event,
          event: "structure_note_updated",
          payload: payload_1,
          resource_type: "data_structure_note"
        ),
        build(:event,
          event: "structure_note_updated",
          payload: payload_2,
          resource_type: "data_structure_note"
        )
      ]

      [{link, title, events}] =
        :notification
        |> insert(events: events, recipient_ids: [user_id])
        |> Email.create()
        |> then(fn {:ok, %{html_body: html_body}} -> html_body end)
        |> Floki.parse_document!()
        |> EmailParser.parse_layout()
        |> EmailParser.parse_events()

      assert link =~ ~r|.*/structures/#{field_parent_id}|
      assert title == "grampa > parent"

      assert [
               {"Evento:", "Structure note updated"},
               {"Dominio:", ^domain_name},
               {"Estructuras hijas:", "child1, child2"}
             ] = events
    end

    test "parent notification will be grouped with field childs" do
      %{id: user_id} = CacheHelpers.put_user()
      %{id: domain_id, name: domain_name} = CacheHelpers.put_domain()
      parent_structure_id = System.unique_integer([:positive])
      child_structure_id = System.unique_integer([:positive])

      child_payload =
        string_params_for(
          :payload,
          data_structure_id: child_structure_id,
          field_parent_id: parent_structure_id,
          domain_ids: [domain_id],
          resource: %{
            name: "child",
            path: ["grampa", "parent"]
          }
        )

      parent_payload =
        string_params_for(
          :payload,
          data_structure_id: parent_structure_id,
          domain_ids: [domain_id],
          resource: %{
            name: "parent",
            path: ["grampa"]
          }
        )

      events = [
        build(:event,
          event: "structure_note_updated",
          payload: child_payload,
          resource_type: "data_structure_note"
        ),
        build(:event,
          event: "structure_note_updated",
          payload: parent_payload,
          resource_type: "data_structure_note"
        )
      ]

      [{link, title, events}] =
        :notification
        |> insert(events: events, recipient_ids: [user_id])
        |> Email.create()
        |> then(fn {:ok, %{html_body: html_body}} -> html_body end)
        |> Floki.parse_document!()
        |> EmailParser.parse_layout()
        |> EmailParser.parse_events()

      assert link =~ ~r|.*/structures/#{parent_structure_id}|
      assert title == "grampa > parent"

      assert [
               {"Evento:", "Structure note updated"},
               {"Dominio:", ^domain_name},
               {"Estructuras hijas:", "child"}
             ] = events
    end

    test "renders multiple structure note events with multiple field notification with same parent" do
      %{id: user_id} = CacheHelpers.put_user()
      %{id: domain_id, name: domain_name} = CacheHelpers.put_domain()
      field_parent_id = System.unique_integer([:positive])
      structure_id_1 = System.unique_integer([:positive])
      structure_id_2 = System.unique_integer([:positive])

      payload_1 =
        string_params_for(
          :payload,
          data_structure_id: structure_id_1,
          field_parent_id: field_parent_id,
          domain_ids: [domain_id],
          resource: %{
            name: "child1",
            path: ["grampa", "parent"]
          }
        )

      payload_2 =
        string_params_for(
          :payload,
          data_structure_id: structure_id_2,
          field_parent_id: field_parent_id,
          domain_ids: [domain_id],
          resource: %{
            name: "child2",
            path: ["grampa", "parent"]
          }
        )

      events = [
        build(:event,
          event: "structure_note_published",
          payload: payload_1,
          resource_type: "data_structure_note"
        ),
        build(:event,
          event: "structure_note_published",
          payload: payload_2,
          resource_type: "data_structure_note"
        ),
        build(:event,
          event: "structure_note_updated",
          payload: payload_1,
          resource_type: "data_structure_note"
        ),
        build(:event,
          event: "structure_note_updated",
          payload: payload_2,
          resource_type: "data_structure_note"
        )
      ]

      [
        {link1, title1, events1},
        {link2, title2, events2}
      ] =
        :notification
        |> insert(events: events, recipient_ids: [user_id])
        |> Email.create()
        |> then(fn {:ok, %{html_body: html_body}} -> html_body end)
        |> Floki.parse_document!()
        |> EmailParser.parse_layout()
        |> EmailParser.parse_events()

      assert link1 =~ ~r|.*/structures/#{field_parent_id}|
      assert title1 == "grampa > parent"

      assert [
               {"Evento:", "Structure note published"},
               {"Dominio:", ^domain_name},
               {"Estructuras hijas:", "child1, child2"}
             ] = events1

      assert link2 =~ ~r|.*/structures/#{field_parent_id}|
      assert title2 == "grampa > parent"

      assert [
               {"Evento:", "Structure note updated"},
               {"Dominio:", ^domain_name},
               {"Estructuras hijas:", "child1, child2"}
             ] = events2
    end

    test "renders notification from multiple events of the same structure note" do
      %{id: user_id} = CacheHelpers.put_user()
      %{id: domain_id, name: domain_name} = CacheHelpers.put_domain()
      structure_id = System.unique_integer([:positive])

      payload =
        string_params_for(
          :payload,
          data_structure_id: structure_id,
          domain_ids: [domain_id],
          resource: %{
            name: "structure",
            path: ["grampa", "parent"]
          }
        )

      events = [
        build(:event,
          event: "structure_note_updated",
          payload: payload,
          resource_type: "data_structure_note"
        ),
        build(:event,
          event: "structure_note_updated",
          payload: payload,
          resource_type: "data_structure_note"
        )
      ]

      [{link, title, events}] =
        :notification
        |> insert(events: events, recipient_ids: [user_id])
        |> Email.create()
        |> then(fn {:ok, %{html_body: html_body}} -> html_body end)
        |> Floki.parse_document!()
        |> EmailParser.parse_layout()
        |> EmailParser.parse_events()

      assert link =~ ~r|.*/structures/#{structure_id}/notes|
      assert title == "grampa > parent > structure"

      assert [
               {"Evento:", "Structure note updated"},
               {"Dominio:", ^domain_name}
             ] = events
    end
  end
end
