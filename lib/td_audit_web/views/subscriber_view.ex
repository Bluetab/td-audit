defmodule TdAuditWeb.SubscriberView do
  use TdAuditWeb, :view

  def render("index.json", %{subscribers: subscribers}) do
    %{data: render_many(subscribers, __MODULE__, "subscriber.json")}
  end

  def render("show.json", %{subscriber: subscriber}) do
    %{data: render_one(subscriber, __MODULE__, "subscriber.json")}
  end

  def render("subscriber.json", %{subscriber: subscriber}) do
    Map.take(subscriber, [:id, :type, :identifier])
  end
end
