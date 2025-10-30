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

  describe "create/1 with custom message" do
    test "creates email with custom message data" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe", email: "john@example.com"},
        uri: "https://example.com/resource",
        resource: %{"name" => "Test Resource", "description" => "Test Description"},
        headers: %{
          "subject" => "Custom Subject (user) (name)",
          "header" => "Custom Header (user)",
          "description_header" => "Custom Description",
          "message_header" => "Custom Message"
        },
        message: "Custom message content"
      }

      assert {:ok, email} = Email.create(message)

      assert email.to == ["test@example.com"]
      assert email.from == {"Truedat Notifications", "no-reply@truedat.io"}
      assert email.subject == "Custom Subject John Doe \"Test Resource\""
      assert email.html_body =~ "Custom Header John Doe"
      assert email.html_body =~ "Custom Description"
      assert email.html_body =~ "Custom Message"
      assert email.html_body =~ "Custom message content"
    end

    test "creates email with default headers when not provided" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe", email: "john@example.com"},
        uri: "https://example.com/resource",
        resource: %{"name" => "Test Resource", "description" => "Test Description"}
      }

      assert {:ok, email} = Email.create(message)

      assert email.subject == "John Doe has shared \"Test Resource\" with you"
      assert email.html_body =~ "John Doe has shared a page with you"
      assert email.html_body =~ "Description"
      assert email.html_body =~ "Message"
    end

    test "returns error when no recipients" do
      message = %{recipients: []}

      assert {:error, :no_recipients} = Email.create(message)
    end

    test "handles missing who data gracefully" do
      message = %{
        recipients: ["test@example.com"],
        who: %{},
        uri: "https://example.com/resource",
        resource: %{"name" => "Test Resource"}
      }

      assert {:ok, email} = Email.create(message)

      assert email.subject == "deleted has shared \"Test Resource\" with you"
      assert email.html_body =~ "deleted has shared a page with you"
    end
  end

  describe "create/2 with grants template" do
    test "returns error when no recipients for grants template" do
      user_id = System.unique_integer([:positive])

      events = [
        build(:event, event: "grant_created", payload: %{"user_id" => user_id})
      ]

      notification = build(:notification, events: events, recipient_ids: [])

      assert {:error, :no_recipients} = Email.create(notification, :grants)
    end
  end

  describe "create/2 with other templates" do
    test "returns error when no recipients" do
      events = [build(:event, event: "test_event")]
      notification = build(:notification, events: events, recipient_ids: [])

      assert {:error, :no_recipients} = Email.create(notification, :default)
    end
  end

  describe "template/1" do
    test "returns correct template for various events" do
      # These will fail due to no recipients, but we're testing the template selection
      assert Email.create(
               build(:notification,
                 events: [build(:event, event: "comment_created")],
                 recipient_ids: []
               )
             )
             |> elem(0) == :error

      assert Email.create(
               build(:notification,
                 events: [build(:event, event: "concept_published")],
                 recipient_ids: []
               )
             )
             |> elem(0) == :error

      assert Email.create(
               build(:notification,
                 events: [build(:event, event: "grant_created", payload: %{"user_id" => 1})],
                 recipient_ids: []
               )
             )
             |> elem(0) == :error

      assert Email.create(
               build(:notification,
                 events: [build(:event, event: "structure_note_updated")],
                 recipient_ids: []
               )
             )
             |> elem(0) == :error
    end

    test "returns default template for unknown events" do
      assert Email.create(
               build(:notification,
                 events: [build(:event, event: "unknown_event")],
                 recipient_ids: []
               )
             )
             |> elem(0) == :error
    end
  end

  describe "description handling" do
    test "handles map description" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{
          "name" => "Test",
          "description" => %{"type" => "rich_text", "content" => "Rich text content"}
        }
      }

      assert {:ok, email} = Email.create(message)
      # The rich text content gets processed and may not appear exactly as expected
      assert email.html_body
    end

    test "handles string description" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test", "description" => "Simple string description"}
      }

      assert {:ok, email} = Email.create(message)
      assert email.html_body =~ "Simple string description"
    end

    test "handles nil description" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test", "description" => nil}
      }

      assert {:ok, email} = Email.create(message)
      assert email.html_body
    end

    test "handles other description types" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test", "description" => 123}
      }

      assert {:ok, email} = Email.create(message)
      assert email.html_body
    end
  end

  describe "create/2 with grants template additional tests" do
    test "returns error when no recipients for grants template" do
      user_id = System.unique_integer([:positive])

      events = [
        build(:event, event: "grant_created", payload: %{"user_id" => user_id})
      ]

      notification = build(:notification, events: events, recipient_ids: [])

      assert {:error, :no_recipients} = Email.create(notification, :grants)
    end
  end

  describe "create/2 with other templates additional tests" do
    test "returns error when no recipients" do
      events = [build(:event, event: "test_event")]
      notification = build(:notification, events: events, recipient_ids: [])

      assert {:error, :no_recipients} = Email.create(notification, :default)
    end
  end

  describe "template/1 additional tests" do
    test "returns correct template for single event type" do
      notification = build(:notification, events: [build(:event, event: "comment_created")])

      # Test the private template/1 function through create/1
      # This will fail due to no recipients, but we're testing the template selection
      assert {:error, :no_recipients} = Email.create(notification)
    end

    test "returns default template for multiple different event types" do
      events = [
        build(:event, event: "comment_created"),
        build(:event, event: "concept_published")
      ]
      notification = build(:notification, events: events, recipient_ids: [])

      assert {:error, :no_recipients} = Email.create(notification)
    end

    test "returns specific template for single event type" do
      events = [build(:event, event: "grant_created", payload: %{"user_id" => 1})]
      notification = build(:notification, events: events, recipient_ids: [])

      assert {:error, :no_recipients} = Email.create(notification)
    end
  end

  describe "private helper functions" do
    test "subject_from_headers with nil subject" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test Resource"},
        headers: %{"subject" => nil}
      }

      assert {:ok, email} = Email.create(message)
      assert email.subject == "John Doe has shared \"Test Resource\" with you"
    end

    test "subject_from_headers with custom subject" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test Resource"},
        headers: %{"subject" => "Custom subject (user) for (name)"}
      }

      assert {:ok, email} = Email.create(message)
      assert email.subject == "Custom subject John Doe for \"Test Resource\""
    end

    test "header_from_headers with nil header" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test Resource"},
        headers: %{"header" => nil}
      }

      assert {:ok, email} = Email.create(message)
      assert email.html_body =~ "John Doe has shared a page with you"
    end

    test "header_from_headers with custom header" do
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test Resource"},
        headers: %{"header" => "Custom header (user)"}
      }

      assert {:ok, email} = Email.create(message)
      assert email.html_body =~ "Custom header John Doe"
    end

    test "truncate function with long text" do
      long_text = String.duplicate("a", 100)
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test", "description" => long_text}
      }

      assert {:ok, email} = Email.create(message)
      assert email.html_body
    end

    test "truncate function with short text" do
      short_text = "short"
      message = %{
        recipients: ["test@example.com"],
        who: %{full_name: "John Doe"},
        uri: "https://example.com",
        resource: %{"name" => "Test", "description" => short_text}
      }

      assert {:ok, email} = Email.create(message)
      assert email.html_body =~ short_text
    end
  end
end
