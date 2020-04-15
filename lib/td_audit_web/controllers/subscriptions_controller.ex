defmodule TdAuditWeb.SubscriptionsController do
  @moduledoc """
  Controller for the subscritions of the system
  """
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.Subscriptions
  alias TdAuditWeb.SubscriptionView
  alias TdAuditWeb.SwaggerDefinitions

  action_fallback(TdAuditWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.subscription_swagger_definitions()
  end

  swagger_path :update do
    description("Create multiple subscriptions")
    produces("application/json")

    parameters do
      event(:body, Schema.ref(:SubscriptionsUpdate), "Subscriptions creation parameters")
    end

    response(201, "OK", Schema.ref(:SubscriptionsResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"subscriptions" => params}) do
    with {:ok, subscriptions} <- Subscriptions.create_subscriptions(params) do
      conn
      |> put_view(SubscriptionView)
      |> render("index.json", subscriptions: subscriptions)
    end
  end
end
