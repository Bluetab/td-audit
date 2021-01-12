defmodule TdAuditWeb.SubscriberController do
  @moduledoc """
  Controller for the subscribers of the system
  """
  use TdAuditWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdAudit.Subscriptions.Subscribers
  alias TdAuditWeb.SwaggerDefinitions

  action_fallback(TdAuditWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.subscriber_swagger_definitions()
  end

  swagger_path :index do
    description("List of subscribers")
    response(200, "OK", Schema.ref(:SubscribersResponse))
  end

  def index(conn, _params) do
    with session <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(session, list(Subscriber))},
         subscribers <- Subscribers.list_subscribers() do
      render(conn, "index.json", subscribers: subscribers)
    end
  end

  swagger_path :create do
    description("Creates a Subscriber")
    produces("application/json")

    parameters do
      subscription(:body, Schema.ref(:SubscriberCreate), "Subscriber create attrs")
    end

    response(201, "OK", Schema.ref(:SubscriberResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"subscriber" => subscriber_params}) do
    with session <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(session, create(Subscriber))},
         {:ok, subscriber} <- Subscribers.create_subscriber(subscriber_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.subscriber_path(conn, :show, subscriber))
      |> render("show.json", subscriber: subscriber)
    end
  end

  swagger_path :show do
    description("Show a Subscriber")
    produces("application/json")

    parameters do
      id(:path, :integer, "Subscriber ID", required: true)
    end

    response(200, "OK", Schema.ref(:SubscriberResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    with session <- conn.assigns[:current_resource],
         subscriber <- Subscribers.get_subscriber!(id),
         {:can, true} <- {:can, can?(session, view(subscriber))} do
      render(conn, "show.json", subscriber: subscriber)
    end
  end

  swagger_path :delete do
    description("Delete Subscriber")
    produces("application/json")

    parameters do
      id(:path, :integer, "Subscriber ID", required: true)
    end

    response(204, "No Content")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    with session <- conn.assigns[:current_resource],
         subscriber <- Subscribers.get_subscriber!(id),
         {:can, true} <- {:can, can?(session, delete(subscriber))},
         {:ok, _} <- Subscribers.delete_subscriber(subscriber) do
      send_resp(conn, :no_content, "")
    end
  end
end
