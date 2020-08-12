defmodule TdAuditWeb.SubscriptionController do
  @moduledoc """
  Controller for the subscritions of the system
  """
  use TdAuditWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdAudit.Map.Helpers
  alias TdAudit.Subscriptions
  alias TdAudit.Subscriptions.Subscriber
  alias TdAudit.Subscriptions.Subscribers
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

  swagger_path :index_by_user do
    description("List of user subscriptions")
    response(200, "OK", Schema.ref(:SubscriptionsResponse))

    parameters do
      filters(:body, Schema.ref(:SubscriptionSearchFilters), "Subscription update attrs")
    end
  end

  def index_by_user(conn, params) do
    with user <- conn.assigns[:current_resource],
         {:subscriber, %Subscriber{} = subscriber} <-
           {:subscriber, Subscribers.get_subscriber_by_user(user.id)},
         filters <- params |> Map.get("filters") |> Map.put("subscriber_id", subscriber.id),
         filters <- Helpers.atomize_keys(filters),
         subscriptions <- Subscriptions.list_subscriptions(filters) do
      render(conn, "index.json", subscriptions: subscriptions)
    else
      {:subscriber, nil} ->
        render(conn, "index.json", subscriptions: [])
    end
  end

  def create(
        conn,
        %{"subscription" => %{"subscriber" => subscriber_params} = subscription_params}
      ) do
    user = conn.assigns[:current_resource]
    subscription_params = with_email(subscription_params)

    subscriber_params =
      case Map.get(subscriber_params, "identifier") do
        nil -> Map.put(subscriber_params, "identifier", "#{user.id}")
        _ -> subscriber_params
      end

    with {:can, true} <- {:can, can?(user, create(subscriber_params))},
         {:ok, %{id: subscriber_id}} <- Subscribers.get_or_create_subscriber(subscriber_params),
         subscription_params <-
           subscription_params
           |> Map.put("subscriber_id", subscriber_id)
           |> Map.delete("subscriber"),
         {:ok, %{id: id}} <- Subscriptions.create_subscription(subscription_params),
         subscription <- Subscriptions.get_subscription!(id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.subscription_path(conn, :show, subscription))
      |> render("show.json", subscription: subscription)
    end
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

  swagger_path :update do
    description("update a Subscription")
    produces("application/json")

    parameters do
      subscription(:body, Schema.ref(:SubscriptionUpdate), "Subscription update attrs")
    end

    response(200, "OK", Schema.ref(:SubscriptionResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}) do
    with user <- conn.assigns[:current_resource],
         id <- String.to_integer(id),
         subscription <- Subscriptions.get_subscription!(id),
         {:can, true} <- {:can, can?(user, update(subscription))},
         subscription_params <- filter_subscription_params(subscription, subscription_params),
         {:ok, %{id: id}} <- Subscriptions.update_subscription(subscription, subscription_params),
         subscription <- Subscriptions.get_subscription!(id) do
      conn
      |> put_resp_header("location", Routes.subscription_path(conn, :show, subscription))
      |> render("show.json", subscription: subscription)
    end
  end

  defp filter_subscription_params(subscription, subscription_params) do
    params =
      subscription_params
      |> Map.take(["periodicity", "scope"])

    case get_in(params, ["scope", "status"]) do
      nil ->
        Map.delete(params, "scope")

      status ->
        scope =
          Map.merge(Helpers.stringify_keys(Map.from_struct(subscription.scope)), %{
            "status" => status
          })

        Map.put(params, "scope", scope)
    end
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

    with user <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(user, delete(subscription))},
         {:ok, %Subscription{}} <- Subscriptions.delete_subscription(subscription) do
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
