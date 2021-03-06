defmodule TdAudit.Notifications do
  @moduledoc """
  The Notifications context
  """

  import Ecto.Query

  alias Ecto.Multi
  alias TdAudit.Audit
  alias TdAudit.Notifications.Email
  alias TdAudit.Notifications.Notification
  alias TdAudit.Notifications.Status
  alias TdAudit.Repo
  alias TdAudit.Subscriptions
  alias TdAudit.Subscriptions.Events
  alias TdAudit.Subscriptions.Subscription
  alias TdCache.UserCache

  def list_notifications(user_id) do
    from(n in Notification, where: ^user_id in n.recipient_ids, order_by: [desc: :id])
    |> Repo.all()
    |> Repo.preload(:events)
  end

  def send_pending do
    Multi.new()
    |> Multi.run(:notifications, fn _, _ -> {:ok, pending()} end)
    |> Multi.run(:emails, fn _, %{notifications: notifications} ->
      emails =
        notifications
        |> Enum.map(&Email.create/1)
        |> Enum.flat_map(fn
          {:ok, email} -> [email]
          _ -> []
        end)

      {:ok, emails}
    end)
    |> Multi.run(:status, &bulk_insert_status(&1, &2, DateTime.utc_now()))
    |> Repo.transaction()
  end

  defp bulk_insert_status(_repo, %{notifications: notifications}, ts) do
    entries = Enum.map(notifications, &%{notification_id: &1.id, status: "sent", inserted_at: ts})
    {:ok, Repo.insert_all(Status, entries)}
  end

  @doc """
  Returns pending notifications with preloaded events and subscription.
  """
  def pending do
    user_map = UserCache.map()

    Notification
    |> join(:inner, [n], s in Status, on: s.notification_id == n.id and s.status == "pending")
    |> join(:left, [n], s in Status, on: s.notification_id == n.id and s.status != "pending")
    |> where([n, _pending, sent], is_nil(sent.id))
    |> preload([:events, subscription: :subscriber])
    |> select([n], n)
    |> Repo.all()
    |> Enum.map(fn %{events: events} = notification ->
      events =
        Enum.map(events, fn %{user_id: user_id} = e ->
          %{e | user: get_user(user_map, user_id)}
        end)

      %{notification | events: events}
    end)
  end

  @doc """
  Generate notifications for subscriptions matching the specified `clauses`.
  """
  def create(clauses) do
    case Audit.max_event_id() do
      nil ->
        :ok

      max_event_id ->
        Multi.new()
        |> Multi.run(:max_event_id, fn _, _ -> {:ok, max_event_id} end)
        |> Multi.run(:subscriptions, &list_subscriptions(&1, &2, clauses))
        |> Multi.run(:update_last_event_id, &update_last_event_id/2)
        |> Multi.run(:subscription_event_ids, &subscription_event_ids/2)
        |> Multi.run(:subscription_recipient_ids, &subscription_recipient_ids/2)
        |> Multi.run(:notifications, &bulk_insert_notifications/2)
        |> Repo.transaction()
    end
  end

  @doc """
  Generate a notification when a resource is shared.
  """
  def share(%{recipients: recipients, user_id: user_id} = message) do
    who =
      case UserCache.get(user_id) do
        {:ok, %{} = user} -> Map.take(user, [:full_name, :email])
        _ -> %{}
      end

    email_map = UserCache.id_to_email_map()

    recipient_ids =
      recipients
      |> Enum.flat_map(fn
        %{"role" => "user", "id" => id} ->
          [id]

        %{"users" => users} ->
          Enum.map(users, &Map.get(&1, "id"))
      end)
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)

    recipients_with_emails = Map.take(email_map, recipient_ids)

    message
    |> Map.put(:recipient_ids, Map.keys(recipients_with_emails))
    |> Map.put(:who, who)
    |> create_shared_notification()

    message
    |> Map.put(:recipients, _recipient_emails = Map.values(recipients_with_emails))
    |> Map.put(:who, who)
    |> Email.create()
  end

  defp create_shared_notification(%{
         user_id: user_id,
         recipient_ids: recipient_ids,
         headers: %{"subject" => subject},
         resource: %{"name" => name},
         who: %{full_name: user},
         uri: uri
       }) do
    message =
      subject
      |> String.replace("(name)", name)
      |> String.replace("(user)", user)

    path =
      uri
      |> URI.parse()
      |> Map.get(:path)

    event = %{
      service: "td_audit",
      event: "share_document",
      payload: %{
        message: message,
        path: path
      },
      ts: DateTime.utc_now(),
      user_id: user_id
    }

    Multi.new()
    |> Multi.run(:create_event, fn _, _ -> Audit.create_event(event) end)
    |> Multi.run(:create_notification, fn _, %{create_event: %{id: event_id}} ->
      insert_shared_notification(recipient_ids, event_id)
    end)
    |> Repo.transaction()
  end

  defp insert_shared_notification(recipient_ids, event_id) do
    changeset = notification_changeset(nil, recipient_ids, "sent")

    # TODO: Refactor. Use Multi.insert, avoid insert_all for a single insert
    with {:ok, %{notification: %{id: notification_id}}} <- Repo.insert(changeset),
         {1, nil} <-
           Repo.insert_all("notifications_events", [
             %{event_id: event_id, notification_id: notification_id}
           ]) do
      {:ok, nil}
    end
  end

  def list_recipients(%{recipient_ids: user_ids}) do
    user_ids
    |> Enum.map(&UserCache.get/1)
    |> Enum.flat_map(fn
      {:ok, %{full_name: full_name, email: email}} when is_binary(email) -> [{full_name, email}]
      _ -> []
    end)
  end

  defp list_subscriptions(_repo, _changes, clauses) do
    {:ok, Subscriptions.list_subscriptions(clauses)}
  end

  defp update_last_event_id(_repo, %{subscriptions: []}), do: {:ok, {0, []}}

  defp update_last_event_id(_repo, %{subscriptions: subscriptions, max_event_id: max_event_id}) do
    ids = Enum.map(subscriptions, & &1.id)

    Subscription
    |> where([s], s.id in ^ids)
    |> select([s], s)
    |> update(set: [last_event_id: ^max_event_id])
    |> Repo.update_all([])
    |> case do
      res -> {:ok, res}
    end
  end

  defp subscription_event_ids(_repo, %{subscriptions: subscriptions, max_event_id: max_event_id}) do
    subscription_event_ids =
      subscriptions
      |> Enum.map(fn s -> {s.id, Events.subscription_event_ids(s, max_event_id)} end)
      |> Enum.reject(fn {_, event_ids} -> event_ids == [] end)
      |> Map.new()

    {:ok, subscription_event_ids}
  end

  defp subscription_recipient_ids(_repo, %{
         subscriptions: subscriptions,
         subscription_event_ids: subscription_event_ids
       }) do
    subscription_recipient_ids =
      subscriptions
      |> Enum.filter(&Map.has_key?(subscription_event_ids, &1.id))
      |> Enum.map(fn s -> {s.id, Subscriptions.list_recipient_ids(s)} end)
      |> Map.new()

    {:ok, subscription_recipient_ids}
  end

  defp bulk_insert_notifications(_repo, %{
         subscription_event_ids: subscription_event_ids,
         subscription_recipient_ids: subscription_recipient_ids
       }) do
    subscription_event_ids
    |> Enum.map(fn {id, event_ids} ->
      recipient_ids = Map.get(subscription_recipient_ids, id)
      {notification_changeset(id, recipient_ids), event_ids}
    end)
    |> Enum.reduce_while(%{}, &reduce_changesets/2)
    |> case do
      {:error, error} ->
        error

      notification_event_ids ->
        entries = Enum.flat_map(notification_event_ids, &event_entries/1)
        Repo.insert_all("notifications_events", entries)
        {:ok, Map.keys(notification_event_ids)}
    end
  end

  defp reduce_changesets({%{} = changeset, events}, %{} = acc) do
    case Repo.insert(changeset) do
      {:ok, notification_status} -> {:cont, Map.put(acc, notification_status, events)}
      error -> {:halt, error}
    end
  end

  defp event_entries({%{notification_id: notification_id}, event_ids}) do
    Enum.map(event_ids, &%{event_id: &1, notification_id: notification_id})
  end

  defp notification_changeset(subscription_id, recipient_ids, status \\ "pending") do
    %{
      status: status,
      notification: %{subscription_id: subscription_id, recipient_ids: recipient_ids}
    }
    |> Status.changeset()
  end

  defp get_user(user_map, id) do
    Map.get(user_map, id, %{id: id, full_name: "deleted", user_name: "deleted"})
  end
end
