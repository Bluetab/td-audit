defmodule TdAuditWeb.EventView do
  use TdAuditWeb, :view
  alias TdAuditWeb.EventView

  def render("index.json", %{events: events}) do
    %{data: render_many(events, EventView, "event.json")}
  end

  def render("show.json", %{event: event}) do
    %{data: render_one(event, EventView, "event.json")}
  end

  def render("event.json", %{event: event}) do
    %{id: event.id,
      service: event.service,
      resource_id: event.resource_id,
      resource_type: event.resource_type,
      event: event.event,
      payload: event.payload,
      user_id: event.user_id,
      user_name: event.user_name,
      ts: event.ts}
  end
end
