defmodule TdAuditWeb.SubscriptionController do
  @moduledoc """
  Controller for the subscritions of the system
  """
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.Subscriptions
  alias TdAudit.Subscriptions.Subscription
  alias TdAuditWeb.SwaggerDefinitions

  action_fallback TdAuditWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.subscription_swagger_definitions()
  end

  swagger_path :index do
    get "/subscriptions"
    description "List of subscriptions"
    response 200, "OK", Schema.ref(:SubscriptionsResponse)
  end

  def index(conn, params) do
    subscriptions = Subscriptions.list_subscriptions_by_filter(params)
    render(conn, "index.json", subscriptions: subscriptions)
  end

  swagger_path :create do
    post "/subscriptions"
    description "Creates a Subscription"
    produces "application/json"
    parameters do
      subscription :body, Schema.ref(:SubscriptionCreate), "Subscription create attrs"
    end
    response 201, "OK", Schema.ref(:SubscriptionResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"subscription" => subscription_params}) do
    with {:ok, %Subscription{} = subscription} <-
      Subscriptions.create_subscription(subscription_params) do
        conn
        |> put_status(:created)
        |> put_resp_header("location", subscription_path(conn, :show, subscription))
        |> render("show.json", subscription: subscription)
    end
  end

  swagger_path :show do
    get "/subscriptions/{id}"
    description "Show a Subscription"
    produces "application/json"
    parameters do
      id :path, :integer, "Subscription ID", required: true
    end
    response 200, "OK", Schema.ref(:SubscriptionResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)
    render(conn, "show.json", subscription: subscription)
  end

  swagger_path :update do
    put "/subscriptions/{id}"
    description "Update Subscription"
    produces "application/json"
    parameters do
      id :path, :integer, "Subscription ID", required: true
      event :body, Schema.ref(:SubscriptionUpdate), "Subscription update attrs"
    end
    response 201, "OK", Schema.ref(:SubscriptionResponse)
    response 400, "Client Error"
  end
  def update(conn, %{"id" => id, "subscription" => subscription_params}) do
    subscription = Subscriptions.get_subscription!(id)

    with {:ok, %Subscription{} = subscription} <- Subscriptions.update_subscription(subscription, subscription_params) do
      render(conn, "show.json", subscription: subscription)
    end
  end

  swagger_path :delete do
    delete "/subscription/{id}"
    description "Delete Subscription"
    produces "application/json"
    parameters do
      id :path, :integer, "Subscription ID", required: true
    end
    response 204, "No Content"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)
    with {:ok, %Subscription{}} <- Subscriptions.delete_subscription(subscription) do
      send_resp(conn, :no_content, "")
    end
  end
end
