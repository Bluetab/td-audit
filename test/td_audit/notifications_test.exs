defmodule TdAudit.NotificationsTest do
  @moduledoc """
  Subscriptions testing module
  """
  use TdAudit.DataCase

  import TdAudit.TestOperators

  alias TdAudit.Notifications

  describe "notifications" do
    test "create/1 creates notifications for subscriptions matching the specified `clauses`" do
      domain_id = System.unique_integer([:positive])
      users = Enum.map(1..3, fn _ -> CacheHelpers.put_user() end)
      role = "foo"
      event = "bar"
      CacheHelpers.put_acl_role_users(domain_id, role, users)

      %{id: event_id} = insert(:event, event: event, payload: %{"domain_ids" => [domain_id]})
      subscriber = %{id: subscriber_id} = insert(:subscriber, type: "role", identifier: role)
      scope = %{events: [event], resource_id: domain_id, resource_type: "domains"}

      %{id: subscription_id} =
        insert(:subscription, periodicity: "minutely", subscriber: subscriber, scope: scope)

      assert {:ok,
              %{
                max_event_id: ^event_id,
                notifications: notifications,
                subscription_events: %{^subscription_id => [%{id: ^event_id}]},
                subscriptions: [
                  %{
                    periodicity: "minutely",
                    scope: %{events: [^event], resource_id: ^domain_id, resource_type: "domains"},
                    subscriber: %{id: ^subscriber_id}
                  }
                ],
                update_last_event_id:
                  {1,
                   [
                     %{
                       last_event_id: ^event_id,
                       periodicity: "minutely",
                       scope: %{
                         events: [^event],
                         resource_id: ^domain_id,
                         resource_type: "domains"
                       },
                       subscriber_id: ^subscriber_id
                     }
                   ]}
              }} = Notifications.create(periodicity: "minutely")

      assert [%{event_ids: [^event_id], recipient_ids: recipient_ids}] = Map.values(notifications)
      assert_lists_equal(recipient_ids, users, &(&1 == &2.id))
    end

    test "create/1 creates notifications for self-reported events" do
      domain_id = System.unique_integer([:positive])
      user = 1
      [event | _] = Notifications.self_reported_event_types()
      CacheHelpers.put_acl_role_users(domain_id, "foo", [user])

      payload = %{
        "recipient_ids" => [user],
        "name" => "foo"
      }

      %{id: event_id} = insert(:event, event: event, payload: payload)

      assert {:ok,
              %{
                max_event_id: ^event_id,
                notifications: notifications,
                self_reported_events: [%{id: ^event_id}]
              }} = Notifications.create(periodicity: "minutely")

      assert [%{event_ids: [^event_id], recipient_ids: [^user]}] = Map.values(notifications)
    end

    test "create/1 only creates self-reported notifications for not notified events" do
      domain_id = System.unique_integer([:positive])
      user = 1
      [event | _] = Notifications.self_reported_event_types()
      CacheHelpers.put_acl_role_users(domain_id, "foo", [user])

      payload = %{
        "recipient_ids" => [user],
        "name" => "foo"
      }

      insert(:event, event: event, payload: payload)
      insert(:event, event: event, payload: payload)
      insert(:event, event: event, payload: payload)
      Notifications.create(periodicity: "minutely")

      %{id: event_id} = insert(:event, event: event, payload: payload)
      %{id: event_id_2} = insert(:event, event: event, payload: payload)

      assert {:ok,
              %{
                max_event_id: ^event_id_2,
                notifications: notifications,
                self_reported_events: [%{id: ^event_id}, %{id: ^event_id_2}]
              }} = Notifications.create(periodicity: "minutely")

      assert [%{event_ids: [^event_id, ^event_id_2], recipient_ids: [^user]}] =
               Map.values(notifications)
    end

    test "create/1 create individual notification for grants events" do
      domain_id = System.unique_integer([:positive])

      %{id: user_id1, email: email, full_name: full_name} =
        create_user(%{full_name: "foo_full_name", email: "foo@foo.net", name: "foo"})

      %{id: user_id2} =
        create_user(%{full_name: "bar_full_name", email: "bar@bar.net", name: "bar"})

      %{id: user_id3} = create_user(%{full_name: "xyz", email: "xyz@xyz.net", name: "xyz"})

      role = "foobar"
      event = "grant_created"

      CacheHelpers.put_acl_role_users(domain_id, role, [user_id1, user_id2, user_id3])

      payload = %{
        "data_structure_id" => 1,
        "detail" => %{},
        "domain_ids" => [domain_id],
        "end_date" => ~D[2022-01-19],
        "resource" => %{"name" => "foo", "description" => "some desc"},
        "start_date" => ~D[2021-01-17],
        "user_id" => user_id1
      }

      %{id: _event_id} = insert(:event, event: event, payload: payload)

      subscriber = %{id: _subscriber_id} = insert(:subscriber, type: "role", identifier: role)

      scope = %{events: [event], resource_id: domain_id, resource_type: "domains"}

      %{id: _subscription_id} =
        insert(:subscription, periodicity: "minutely", subscriber: subscriber, scope: scope)

      assert {:ok, _} = Notifications.create(periodicity: "minutely")

      assert {:ok, %{emails: [notification_email]}} = Notifications.send_pending()

      assert %Bamboo.Email{to: [{^full_name, ^email}]} = notification_email
    end

    test "generate_custom_notification/1 shares an email with a list of recipients and creates notification" do
      %{id: user_id} =
        sender = create_user(%{full_name: "xyz", email: "xyz@bar.net", name: "xyz"})

      %{id: id1, email: email1} =
        create_user(%{full_name: "xyz", email: "foo@bar.net", name: "bar"})

      %{id: id2, email: email2} =
        create_user(%{full_name: "xyz", email: "bar@baz.net", name: "baz"})

      description = "bar"
      name = "foo"
      resource = %{"name" => name, "description" => description}
      uri = "http://foo/bar"
      email_message = "foo"
      header = "foo (user)"
      subject = "foo (user) and bar (name)"
      message_header = "bar"
      description_header = "foo"

      headers = %{
        "header" => header,
        "subject" => subject,
        "message_header" => message_header,
        "description_header" => description_header
      }

      recipients = [
        %{"id" => id1, "role" => "user"},
        %{
          "id" => 1,
          "role" => "group",
          "users" => [
            %{"id" => id1, "role" => "user"},
            %{"id" => id2, "role" => "user"}
          ]
        }
      ]

      message = %{
        resource: resource,
        uri: uri,
        message: email_message,
        headers: headers,
        recipients: recipients,
        user_id: user_id
      }

      assigns = %{
        description: description,
        description_header: description_header,
        header: String.replace(header, "(user)", sender.full_name),
        message: email_message,
        message_header: message_header,
        name: name,
        uri: uri,
        footer: footer()
      }

      subject =
        subject
        |> String.replace("(user)", sender.full_name)
        |> String.replace("(name)", ~s("#{name}"))

      assert {:ok, email} = Notifications.generate_custom_notification(message)
      assert %Bamboo.Email{assigns: ^assigns, subject: ^subject, to: to} = email
      assert [email1, email2] <|> to

      assert [
               %TdAudit.Notifications.Notification{
                 events: [
                   %TdAudit.Audit.Event{
                     event: "share_document",
                     payload: %{"message" => "foo xyz and bar foo", "path" => "/bar"},
                     service: "td_audit",
                     user_id: ^user_id
                   }
                 ],
                 recipient_ids: recipient_ids
               }
             ] = Notifications.list_notifications(id1)

      assert [id1, id2] <|> recipient_ids
    end

    test "generate_custom_notification/1 creates notification from external source" do
      %{id: user_id} = create_user(%{full_name: "xyz", email: "xyz@bar.net", name: "xyz"})
      %{id: id1} = create_user(%{full_name: "xyz", email: "foo@bar.net", name: "bar"})
      %{id: id2} = create_user(%{full_name: "xyz", email: "bar@baz.net", name: "baz"})

      uri = "http://foo/bar"
      message = "foo"
      subject = "foo subject"

      headers = %{
        "subject" => subject
      }

      recipients = [
        %{"id" => id1, "role" => "user"},
        %{
          "id" => 1,
          "role" => "group",
          "users" => [
            %{"id" => id1, "role" => "user"},
            %{"id" => id2, "role" => "user"}
          ]
        }
      ]

      message = %{
        uri: uri,
        message: message,
        headers: headers,
        recipients: recipients,
        user_id: user_id
      }

      assert {:ok, nil} = Notifications.generate_custom_notification(message)

      assert [
               %TdAudit.Notifications.Notification{
                 events: [
                   %TdAudit.Audit.Event{
                     event: "external_notification",
                     payload: %{
                       "message" => "foo",
                       "subject" => "foo subject",
                       "path" => "http://foo/bar"
                     },
                     service: "td_audit",
                     user_id: ^user_id
                   }
                 ],
                 recipient_ids: recipient_ids
               }
             ] = Notifications.list_notifications(id1)

      assert [id1, id2] <|> recipient_ids
    end
  end

  test "list_recipients/1 lists users with non-nil emails with full names" do
    %{id: id1} = create_user(%{full_name: "Foo", email: "foo@example.com"})
    %{id: id2} = create_user(%{full_name: "Bar", email: "bar@example.com"})
    %{id: id3} = create_user(%{full_name: "Baz has no email", email: nil})

    notification = insert(:notification, recipient_ids: [id1, id2, id3])

    assert [{"Foo", "foo@example.com"}, {"Bar", "bar@example.com"}] =
             Notifications.list_recipients(notification)
  end

  test "list_notifications/1 lists with read mark" do
    %{id: id1} = create_user(%{full_name: "Foo", email: "foo@example.com"})
    %{id: id2} = create_user(%{full_name: "Bar", email: "bar@example.com"})
    %{id: id3} = create_user(%{full_name: "Baz has no email"})

    notification = insert(:notification, recipient_ids: [id1, id2, id3])

    insert(:notifications_read_by_recipients, notification_id: notification.id, recipient_id: id1)
    insert(:notifications_read_by_recipients, notification_id: notification.id, recipient_id: id2)

    assert [%{read_mark: true}] = Notifications.list_notifications(id1)
    assert [%{read_mark: true}] = Notifications.list_notifications(id2)
    assert [%{read_mark: false}] = Notifications.list_notifications(id3)
  end

  test "read_notifications/2 mark it as read only for the reader" do
    %{id: id1} = create_user(%{full_name: "Foo", email: "foo@example.com"})
    %{id: id2} = create_user(%{full_name: "Bar", email: "bar@example.com"})
    %{id: id3} = create_user(%{full_name: "Baz has no email"})

    notification = insert(:notification, recipient_ids: [id1, id2, id3])

    Notifications.read(notification.id, id3)

    assert [%{read_mark: false}] = Notifications.list_notifications(id1)
    assert [%{read_mark: false}] = Notifications.list_notifications(id2)
    assert [%{read_mark: true}] = Notifications.list_notifications(id3)
  end

  defp config, do: Application.fetch_env!(:td_audit, TdAudit.Notifications.Email)

  defp footer do
    footer =
      config()
      |> Keyword.fetch!(:footer)

    version = Application.spec(:td_audit, :vsn)
    "#{footer} v#{version}"
  end

  defp create_user(%{} = params) do
    CacheHelpers.put_user(params)
  end
end
