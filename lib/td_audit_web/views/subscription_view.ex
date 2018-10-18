defmodule TdAuditWeb.SubscriptionView do
  use TdAuditWeb, :view
  alias TdAuditWeb.SubscriptionView

  def render("index.json", %{subscriptions: subscriptions}) do
    %{data: render_many(subscriptions, SubscriptionView, "subscription.json")}
  end

  def render("show.json", %{subscription: subscription}) do
    %{data: render_one(subscription, SubscriptionView, "subscription.json")}
  end

  def render("subscription.json", %{subscription: subscription}) do
    %{
      id: subscription.id,
      resource_id: subscription.resource_id,
      resource_type: subscription.resource_type,
      event: subscription.event,
      user_email: subscription.user_email,
      periodicity: subscription.periodicity
    }
  end
end
