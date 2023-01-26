defmodule TdAuditWeb.NotificationView do
  use TdAuditWeb, :view

  alias TdAudit.Support.NoteEventsAggregator
  alias TdAuditWeb.EventView

  def render("index.json", %{notifications: notifications}) do
    %{data: render_many(notifications, __MODULE__, "notifications.json")}
  end

  def render("notifications.json", %{notification: notification}) do
    events =
      notification.events
      |> NoteEventsAggregator.maybe_group_events()
      |> render_many(EventView, "event.json")
      |> Enum.map(&with_name_and_path/1)

    notification
    |> Map.take([:id, :inserted_at, :read_mark])
    |> Map.put(:events, events)
  end

  defp with_name_and_path(event) do
    Map.merge(event, %{
      name: EventView.resource_name(event),
      path: EventView.path(event)
    })
  end
end
