defmodule TdAuditWeb.SubscriptionController do
  @moduledoc """
  Controller for the subscritions of the system
  """
  use TdAuditWeb, :controller
  use PhoenixSwagger

  alias TdAudit.Subscriptions
  alias TdAudit.Subscriptions.Subscription
  alias TdAuditWeb.SwaggerDefinitions

  alias TdCache.UserCache

  action_fallback(TdAuditWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.subscription_swagger_definitions()
  end

  swagger_path :index do
    description("List of subscriptions")
    response(200, "OK", Schema.ref(:SubscriptionsResponse))
  end

  def index(conn, params) do
    subscriptions = Subscriptions.list_subscriptions(params)
    render(conn, "index.json", subscriptions: subscriptions)
  end

  swagger_path :create do
    description("Creates a Subscription")
    produces("application/json")

    parameters do
      subscription(:body, Schema.ref(:SubscriptionCreate), "Subscription create attrs")
    end

    response(201, "OK", Schema.ref(:SubscriptionResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"subscription" => subscription_params}) do
    subscription_params = with_email(subscription_params)

    with {:ok, %{id: id}} <- Subscriptions.create_subscription(subscription_params),
         subscription <- Subscriptions.get_subscription!(id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.subscription_path(conn, :show, subscription))
      |> render("show.json", subscription: subscription)
    end
  end

  swagger_path :show do
    description("Show a Subscription")
    produces("application/json")

    parameters do
      id(:path, :integer, "Subscription ID", required: true)
    end

    response(200, "OK", Schema.ref(:SubscriptionResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)
    render(conn, "show.json", subscription: subscription)
  end

  swagger_path :delete do
    description("Delete Subscription")
    produces("application/json")

    parameters do
      id(:path, :integer, "Subscription ID", required: true)
    end

    response(204, "No Content")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(id)

    with {:ok, %Subscription{}} <- Subscriptions.delete_subscription(subscription) do
      send_resp(conn, :no_content, "")
    end
  end

  defp with_email(subscription_params) do
    case Map.has_key?(subscription_params, "user_email") do
      true ->
        subscription_params

      false ->
        email_from_full_name(subscription_params)
    end
  end

  defp email_from_full_name(%{"full_name" => nil} = subscription_params), do: subscription_params

  defp email_from_full_name(%{"full_name" => full_name} = subscription_params) do
    email =
      full_name
      |> UserCache.get_by_name!()
      |> Map.get(:email)

    Map.put(subscription_params, "user_email", email)
  end

  defp email_from_full_name(subscription_params), do: subscription_params
end
