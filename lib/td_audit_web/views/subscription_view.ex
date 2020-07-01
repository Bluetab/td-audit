defmodule TdAuditWeb.SubscriptionView do
  use TdAuditWeb, :view

  alias TdAuditWeb.ScopeView
  alias TdAuditWeb.SubscriberView

  def render("index.json", %{subscriptions: subscriptions}) do
    %{data: render_many(subscriptions, __MODULE__, "subscription.json")}
  end

  def render("show.json", %{subscription: subscription}) do
    %{data: render_one(subscription, __MODULE__, "subscription.json")}
  end

  def render("subscription.json", %{
        subscription: %{scope: scope, subscriber: subscriber} = subscription
      }) do
    scope = render_one(scope, ScopeView, "scope.json")
    subscriber = render_one(subscriber, SubscriberView, "subscriber.json")

    subscription
    |> Map.take([:id, :periodicity, :last_event_id])
    |> Map.put(:subscriber, subscriber)
    |> Map.put(:scope, scope)
  end
end
