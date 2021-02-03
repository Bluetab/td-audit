defmodule TdAuditWeb.SubscriptionController do
  @moduledoc """
  Controller for the subscritions of the system
  """
  use TdAuditWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdAudit.Auth.Claims
  alias TdAudit.Map.Helpers
  alias TdAudit.Subscriptions
  alias TdAudit.Subscriptions.Subscriber
  alias TdAudit.Subscriptions.Subscribers
  alias TdAudit.Subscriptions.Subscription
  alias TdAuditWeb.SwaggerDefinitions
  alias TdCache.ConceptCache
  alias TdCache.DomainCache
  alias TdCache.RuleCache
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
    with claims <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(claims, index(params))} do
      subscriptions =
        params
        |> Subscriptions.list_subscriptions()
        |> Enum.map(&with_resource/1)

      render(conn, "index.json", subscriptions: subscriptions)
    end
  end

  def index_by_user(conn, params) do
    with %{user_id: user_id} <- conn.assigns[:current_resource],
         {:subscriber, %Subscriber{} = subscriber} <-
           {:subscriber, Subscribers.get_subscriber_by_user(user_id)},
         filters <- params |> Map.get("filters") |> Map.put("subscriber_id", subscriber.id),
         filters <- Helpers.atomize_keys(filters),
         subscriptions <- Subscriptions.list_subscriptions(filters) do
      render(conn, "index.json", subscriptions: subscriptions)
    else
      {:subscriber, nil} ->
        render(conn, "index.json", subscriptions: [])
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

  # def create(
  #       conn,
  #       %{"subscription" => %{"subscriber" => subscriber_params} = subscription_params}
  #     ) do
  #   %Claims{user_id: user_id} = claims = conn.assigns[:current_resource]
  #   subscriber_params =
  #     case Map.get(subscriber_params, "identifier") do
  #       nil -> Map.put(subscriber_params, "identifier", "#{user_id}")
  #       _ -> subscriber_params
  #     end

  #   with {:can, true} <- {:can, can?(claims, create(subscriber_params))},
  #        {:ok, %{id: subscriber_id}} <- Subscribers.get_or_create_subscriber(subscriber_params),
  #        subscription_params <-
  #          subscription_params
  #          |> Map.put("subscriber_id", subscriber_id)
  #          |> Map.delete("subscriber"),
  #        {:ok, %{id: id}} <- Subscriptions.create_subscription(subscription_params),
  #        subscription <- Subscriptions.get_subscription!(id) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.subscription_path(conn, :show, subscription))
  #     |> render("show.json", subscription: subscription)
  #   end
  # end

  def create(conn, %{"subscription" => subscription_params}) do
    with claims <- conn.assigns[:current_resource],
         {:ok, subscriber} <- get_subscriber(claims, subscription_params),
         {:can, true} <- {:can, can?(claims, create(subscriber))},
         {:ok, subscription} <- Subscriptions.create_subscription(subscriber, subscription_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.subscription_path(conn, :show, subscription))
      |> render("show.json", subscription: subscription)
    end
  end

  defp get_subscriber(_claims, %{"subscriber_id" => subscriber_id}) do
    {:ok, Subscribers.get_subscriber!(subscriber_id)}
  end

  defp get_subscriber(claims, %{"subscriber" => subscriber_params}) do
    subscriber_params =
      case Map.get(subscriber_params, "identifier") do
        nil -> Map.put(subscriber_params, "identifier", "#{claims.user_id}")
        _ -> subscriber_params
      end

    with {:can, true} <- {:can, can?(claims, create_subscriber(subscriber_params))} do
      Subscribers.get_or_create_subscriber(subscriber_params)
    end
  end

  defp get_subscriber(_claims, _subscriber_params) do
    {:ok, nil}
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
    with claims <- conn.assigns[:current_resource],
         subscription <- Subscriptions.get_subscription!(id),
         {:can, true} <- {:can, can?(claims, show(subscription))} do
      render(conn, "show.json", subscription: with_resource(subscription))
    end
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
    with claims <- conn.assigns[:current_resource],
         subscription <- Subscriptions.get_subscription!(id),
         {:can, true} <- {:can, can?(claims, update(subscription))},
         {:ok, subscription} <- Subscriptions.update_subscription(subscription, subscription_params) do
      conn
      |> put_resp_header("location", Routes.subscription_path(conn, :show, subscription))
      |> render("show.json", subscription: subscription)
    end
  end

  # defp filter_subscription_params(subscription, subscription_params) do
  #   params =
  #     subscription_params
  #     |> Map.take(["periodicity", "scope"])

  #   case get_in(params, ["scope", "status"]) do
  #     nil ->
  #       Map.delete(params, "scope")

  #     status ->
  #       scope =
  #         Map.merge(Helpers.stringify_keys(Map.from_struct(subscription.scope)), %{
  #           "status" => status
  #         })

  #       Map.put(params, "scope", scope)
  #   end
  # end

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

    with claims <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(claims, delete(subscription))},
         {:ok, %Subscription{}} <- Subscriptions.delete_subscription(subscription) do
      send_resp(conn, :no_content, "")
    end
  end

  defp with_resource(%{scope: %{resource_type: "concept"}} = subscription) do
    case ConceptCache.get(subscription.scope.resource_id) do
      {:ok, resource} when not is_nil(resource) ->
        Map.put(
          subscription,
          :resource,
          Map.take(resource, [:id, :name, :business_concept_version_id])
        )

      _ ->
        subscription
    end
  end

  defp with_resource(%{scope: %{resource_type: domain_type}} = subscription)
       when domain_type in ~w(domain domains) do
    case DomainCache.get(subscription.scope.resource_id) do
      {:ok, resource} when not is_nil(resource) ->
        Map.put(subscription, :resource, Map.take(resource, [:id, :name]))

      _ ->
        subscription
    end
  end

  defp with_resource(%{scope: %{resource_type: "rule"}} = subscription) do
    case RuleCache.get(subscription.scope.resource_id) do
      {:ok, resource} when not is_nil(resource) ->
        Map.put(subscription, :resource, Map.take(resource, [:id, :name]))

      _ ->
        subscription
    end
  end

  defp with_resource(subscription), do: subscription

  swagger_path :index_by_user do
    description("List of user subscriptions")
    response(200, "OK", Schema.ref(:SubscriptionsResponse))

    parameters do
      filters(:body, Schema.ref(:SubscriptionSearchFilters), "Subscription update attrs")
    end
  end
end
