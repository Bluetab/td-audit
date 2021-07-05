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
      UserCache.put(u1)
      UserCache.put(u2)

      on_exit(fn ->
        UserCache.delete(sender.id)
        UserCache.delete(u1.id)
        UserCache.delete(u2.id)
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
        %{"id" => Map.get(u1, :id), "role" => "user"},
        %{
          "id" => 1,
          "role" => "group",
          "users" => [
            %{"id" => Map.get(u1, :id), "role" => "user"},
            %{"id" => Map.get(u2, :id), "role" => "user"}
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

      assert {:ok, email} = Notifications.share(message)
      assert %Bamboo.Email{assigns: ^assigns, subject: ^subject, to: ^to} = email
    end
  end

  test "list_recipients/1 lists users with non-nil emails with full names" do
    %{id: id1} = create_user(%{full_name: "Foo", email: "foo@example.com"})
    %{id: id2} = create_user(%{full_name: "Bar", email: "bar@example.com"})
    %{id: id3} = create_user(%{full_name: "Baz has no email"})

    notification = insert(:notification, recipient_ids: [id1, id2, id3])

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

  defp create_user(%{id: id} = user) do
    on_exit(fn -> UserCache.delete(id) end)
    UserCache.put(user)
    user
  end

  defp create_user(%{} = params) do
    params
    |> Map.put(:id, System.unique_integer([:positive]))
    |> create_user()
  end
end
