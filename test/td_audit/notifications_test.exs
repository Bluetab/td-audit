defmodule TdAudit.NotificationsTest do
  @moduledoc """
  Subscriptions testing module
  """
  use TdAudit.DataCase

  alias TdAudit.Notifications
  alias TdCache.UserCache

  describe "notifications" do
    setup do
      sender = %{
        id: :random.uniform(1_000_000),
        full_name: "xyz",
        name: "xyz",
        email: "xyz@bar.net"
      }

      u1 = %{id: :random.uniform(1_000_000), full_name: "xyz", name: "bar", email: "foo@bar.net"}
      u2 = %{id: :random.uniform(1_000_000), full_name: "xyz", name: "baz", email: "bar@baz.net"}

      UserCache.put(sender)

      on_exit(fn ->
        UserCache.delete(sender.id)
      end)

      [sender: sender, users: [u1, u2]]
    end

    test "share/1 shares an email with a list of recipients", %{sender: sender, users: [u1, u2]} do
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

  defp config, do: Application.fetch_env!(:td_audit, TdAudit.Notifications.Email)

  defp footer do
    footer =
      config()
      |> Keyword.fetch!(:footer)

    version = Application.spec(:td_audit, :vsn)
    "#{footer} v#{version}"
  end
end
