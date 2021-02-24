defmodule TdAudit.NotificationsTest do
  @moduledoc """
  Subscriptions testing module
  """
  use TdAudit.DataCase

  alias TdAudit.Notifications
  alias TdCache.AclCache
  alias TdCache.UserCache

  describe "notifications" do
    test "create/1 creates notifications for subscriptions matching the specified `clauses`" do
      domain_id = System.unique_integer([:positive])
      user_ids = Enum.map(1..3, fn _ -> System.unique_integer([:positive]) end)
      role = "foo"
      event = "bar"
      AclCache.set_acl_role_users("domain", domain_id, role, user_ids)

      on_exit(fn ->
        AclCache.delete_acl_role_users("domain", domain_id, role)
      end)

      %{id: event_id} = insert(:event, event: event, payload: %{"domain_ids" => [domain_id]})
      subscriber = %{id: subscriber_id} = insert(:subscriber, type: "role", identifier: role)
      scope = %{events: [event], resource_id: domain_id, resource_type: "domains"}

      %{id: subscription_id} =
        insert(:subscription, periodicity: "minutely", subscriber: subscriber, scope: scope)

      {:ok,
       %{
         max_event_id: ^event_id,
         notifications: [
           %{
             notification: %{subscription_id: ^subscription_id, recipient_ids: ^user_ids},
             status: "pending"
           }
         ],
         subscription_event_ids: %{^subscription_id => [^event_id]},
         subscription_recipient_ids: %{^subscription_id => ^user_ids},
         subscriptions: [
           %{
             periodicity: "minutely",
             scope: %{events: [^event], resource_id: ^domain_id, resource_type: "domains"},
             subscriber_id: ^subscriber_id
           }
         ],
         update_last_event_id:
           {1,
            [
              %{
                last_event_id: ^event_id,
                periodicity: "minutely",
                scope: %{events: [^event], resource_id: ^domain_id, resource_type: "domains"},
                subscriber_id: ^subscriber_id
              }
            ]}
       }} = Notifications.create(periodicity: "minutely")
    end

    test "share/1 shares an email with a list of recipients" do
      sender = %{
        id: System.unique_integer(),
        full_name: "xyz",
        name: "xyz",
        email: "xyz@bar.net"
      }

      u1 = %{id: System.unique_integer(), full_name: "xyz", name: "bar", email: "foo@bar.net"}
      u2 = %{id: System.unique_integer(), full_name: "xyz", name: "baz", email: "bar@baz.net"}

      UserCache.put(sender)

      on_exit(fn ->
        UserCache.delete(sender.id)
      end)

      user_id = Map.get(sender, :id)
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
        %{"id" => Map.get(u1, :id), "role" => "user", "email" => Map.get(u1, :email)},
        %{
          "id" => 1,
          "role" => "group",
          "users" => [
            %{"id" => Map.get(u1, :id), "role" => "user", "email" => Map.get(u1, :email)},
            %{"id" => Map.get(u2, :id), "role" => "user", "email" => Map.get(u2, :email)}
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
        |> String.replace("(name)", "\"#{name}\"")

      to = Enum.map([u1, u2], & &1.email)

      assert %Bamboo.Email{assigns: ^assigns, subject: ^subject, to: ^to} =
               Notifications.share(message)
    end
  end

  test "list_recipients/1 lists user emails with full names" do
    UserCache.put(%{id: 1, full_name: "Foo", email: "foo@example.com"})
    UserCache.put(%{id: 2, full_name: "Bar", email: "bar@example.com"})

    on_exit(fn ->
      UserCache.delete(1)
      UserCache.delete(2)
    end)

    notification = insert(:notification, recipient_ids: [1, 2])

    assert [{"Foo", "foo@example.com"}, {"Bar", "bar@example.com"}] =
             Notifications.list_recipients(notification)
  end

  defp config, do: Application.fetch_env!(:td_audit, TdAudit.Notifications.Email)

  defp footer do
    footer =
      config()
      |> Keyword.fetch!(:footer)

    version = Application.spec(:td_audit, :vsn)
    "#{footer} v#{version}"
  end
end
