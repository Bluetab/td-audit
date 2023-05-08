defmodule TdAudit.Notifications do
  @moduledoc """
  The Notifications context
  """

  import Ecto.Query

  alias Ecto.Multi
  alias TdAudit.Audit
  alias TdAudit.Audit.Event
  alias TdAudit.Notifications.Email
  alias TdAudit.Notifications.Notification
  alias TdAudit.Notifications.NotificationsReadByRecipients
  alias TdAudit.Notifications.Status
  alias TdAudit.Repo
  alias TdAudit.Subscriptions
  alias TdAudit.Subscriptions.Events
  alias TdAudit.Subscriptions.Subscription
  alias TdCache.UserCache

  # Array with all events that not need subscription. Are self reported
  @self_reported_event_type "grant_request_rejection"

  def self_reported_event_type, do: @self_reported_event_type

  def list_notifications(user_id) do
    user_id
    |> query_user_notifications
    |> Repo.all()
    |> Repo.preload(:events)
  end

  def query_user_notifications(user_id) do
    from(n in Notification,
      where: ^user_id in n.recipient_ids,
      order_by: [desc: :id],
      left_join: reads in NotificationsReadByRecipients,
      on: reads.recipient_id == ^user_id and reads.notification_id == n.id,
      group_by: n.id,
      select: %{n | read_mark: count(reads.id) > 0}
    )
  end

  def read(notification_id, recipient_id) do
    with notification when not is_nil(notification) <- Repo.get(Notification, notification_id) do
      case Repo.get_by(NotificationsReadByRecipients,
             notification_id: notification_id,
             recipient_id: recipient_id
           ) do
        nil -> insert_read_mark(notification, recipient_id)
        read -> read
      end
    end
  end

  def insert_read_mark(notification, recipient_id) do
    notification
    |> NotificationsReadByRecipients.changeset(recipient_id)
    |> Repo.insert()
  end

  def send_pending do
    Multi.new()
    |> Multi.run(:notifications, fn _, _ -> {:ok, pending()} end)
    |> Multi.run(:emails, fn _, %{notifications: notifications} ->
      emails =
        notifications
        |> Enum.map(&Email.create/1)
        |> Enum.flat_map(fn
          {:ok, email} when is_list(email) -> email
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
        |> Multi.run(:subscription_events, &subscription_events/2)
        |> Multi.run(:self_reported_events, &get_self_reported_events/2)
        |> Multi.run(:notifications, &bulk_insert_notifications/2)
        |> Repo.transaction()
    end
  end

  @doc """
  Generate a notification
  """
  def generate_custom_notification(%{recipients: recipients, user_id: user_id} = message) do
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

        %{"users_names" => users_names} ->
          Enum.map(users_names, fn user_name ->
            {:ok, %{id: id}} = UserCache.get_by_user_name(user_name)
            id
          end)

        %{"users_external_ids" => external_ids} ->
          Enum.map(external_ids, fn external_id ->
            {:ok, %{id: id}} = UserCache.get_by_external_id(external_id)
            id
          end)
      end)
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)

    recipients_with_emails = Map.take(email_map, recipient_ids)

    message
    |> Map.put(:recipient_ids, Map.keys(recipients_with_emails))
    |> Map.put(:who, who)
    |> create_custom_notification()

    # Create mail for share notification message
    case message do
      %{resource: _resource} ->
        message
        |> Map.put(:recipients, _recipient_emails = Map.values(recipients_with_emails))
        |> Map.put(:who, who)
        |> Email.create()

      _ ->
        {:ok, nil}
    end
  end

  defp create_custom_notification(%{recipient_ids: recipient_ids, uri: uri} = message) do
    path =
      uri
      |> URI.parse()
      |> Map.get(:path)

    message =
      message
      |> Map.put(:path, path)

    event = create_custom_notification_event(message)

    Multi.new()
    |> Multi.run(:create_event, fn _, _ -> Audit.create_event(event) end)
    |> Multi.run(:create_notification, fn _, %{create_event: %{id: event_id}} ->
      insert_custom_notification(recipient_ids, event_id)
    end)
    |> Repo.transaction()
  end

  # Create custom notification event for shared notifications
  defp create_custom_notification_event(%{
         user_id: user_id,
         headers: %{"subject" => subject},
         resource: %{"name" => name},
         who: %{full_name: user},
         path: path
       }) do
    message =
      subject
      |> String.replace("(name)", name)
      |> String.replace("(user)", user)

    %{
      service: "td_audit",
      event: "share_document",
      payload: %{
        message: message,
        path: path
      },
      ts: DateTime.utc_now(),
      user_id: user_id
    }
  end

  # Create custom notification event for external notifications
  defp create_custom_notification_event(%{
         user_id: user_id,
         headers: %{"subject" => subject},
         message: message,
         uri: uri
       }) do
    %{
      service: "td_audit",
      event: "external_notification",
      payload: %{
        subject: subject,
        message: message,
        path: uri
      },
      ts: DateTime.utc_now(),
      user_id: user_id
    }
  end

  defp insert_custom_notification(recipient_ids, event_id) do
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

  defp subscription_events(_repo, %{subscriptions: subscriptions, max_event_id: max_event_id}) do
    subscription_events =
      subscriptions
      |> Enum.map(fn s -> {s.id, Events.subscription_events(s, max_event_id)} end)
      |> Enum.reject(fn {_, events} -> events == [] end)
      |> Map.new()

    {:ok, subscription_events}
  end

  defp get_self_reported_events(_repo, %{max_event_id: max_event_id}) do
    {:ok,
     Event
     |> where([e], e.event == @self_reported_event_type)
     |> where([e], e.id <= ^max_event_id)
     |> join(:left, [e], ne in "notifications_events",
       as: :notification_event,
       on: e.id == ne.event_id
     )
     |> where([notification_event: ne], is_nil(ne.event_id))
     |> Repo.all()}
  end

  defp bulk_insert_notifications(_repo, %{
         subscriptions: subscriptions,
         subscription_events: subscription_events,
         self_reported_events: self_reported_events
       }) do
    subscription_events_recipient_ids =
      subscriptions
      |> Enum.reduce(%{}, fn %{id: id} = subscription, acc ->
        case Map.get(subscription_events, id, []) do
          [_ | _] = event ->
            Map.put(acc, id, Subscriptions.list_recipient_ids(subscription, event))

          _ ->
            acc
        end
      end)

    self_reported_events_recipient_ids =
      Enum.reduce(
        self_reported_events,
        %{},
        fn %{id: event_id, payload: payload}, acc ->
          Map.put(acc, event_id, Map.get(payload, "recipient_ids", []))
        end
      )

    subscription_events_recipient_ids
    |> Map.put(nil, self_reported_events_recipient_ids)
    |> Enum.flat_map(fn
      {subscription_id, recipients} ->
        info_events(subscription_id, group_by_common_events(recipients))
    end)
    |> Enum.reduce_while(%{}, &reduce_changesets/2)
    |> case do
      {:error, error} ->
        error

      notification_id_to_events ->
        entries = Enum.flat_map(notification_id_to_events, &event_entries/1)
        Repo.insert_all("notifications_events", entries)

        {:ok, notification_id_to_events}
    end
  end

  def group_by_common_events(user_by_events) do
    Enum.reduce(
      user_by_events,
      %{},
      &reduce/2
    )
    |> Enum.group_by(fn {_key, val} -> val end, fn {key, _val} -> key end)
  end

  defp reduce({event_id, recipient_ids}, acc) do
    Enum.reduce(
      recipient_ids,
      acc,
      fn recipient_id, acc ->
        Map.update(
          acc,
          recipient_id,
          MapSet.new([event_id]),
          fn event_id_set -> MapSet.put(event_id_set, event_id) end
        )
      end
    )
  end

  defp info_events(subscription_id, event_set_to_recipient_ids) do
    Enum.map(
      event_set_to_recipient_ids,
      fn {event_set, recipient_ids} ->
        {event_set, notification_changeset(subscription_id, recipient_ids),
         event_set_to_recipient_ids}
      end
    )
  end

  defp reduce_changesets({event_ids_set, %{} = changeset, _event_set_to_recipient_ids}, %{} = acc) do
    case Repo.insert(changeset) do
      {:ok, %{notification_id: notification_id, notification: %{recipient_ids: recipient_ids}}} ->
        {:cont,
         Map.put(acc, notification_id, %{
           event_ids: event_ids_set |> MapSet.to_list(),
           recipient_ids: recipient_ids
         })}

      error ->
        {:halt, error}
    end
  end

  defp event_entries({notification_id, %{event_ids: event_ids}}) do
    Enum.map(
      event_ids,
      fn event_id ->
        %{event_id: event_id, notification_id: notification_id}
      end
    )
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
