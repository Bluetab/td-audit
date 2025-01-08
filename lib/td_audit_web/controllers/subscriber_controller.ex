defmodule TdAuditWeb.SubscriberController do
  @moduledoc """
  Controller for the subscribers of the system
  """
  use TdAuditWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAudit.Subscriptions.Subscribers

  action_fallback(TdAuditWeb.FallbackController)

  def index(conn, _params) do
    with claims <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(claims, list(Subscriber))},
         subscribers <- Subscribers.list_subscribers() do
      render(conn, "index.json", subscribers: subscribers)
    end
  end

  def create(conn, %{"subscriber" => subscriber_params}) do
    with claims <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(claims, create(Subscriber))},
         {:ok, subscriber} <- Subscribers.create_subscriber(subscriber_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.subscriber_path(conn, :show, subscriber))
      |> render("show.json", subscriber: subscriber)
    end
  end

  def show(conn, %{"id" => id}) do
    with claims <- conn.assigns[:current_resource],
         subscriber <- Subscribers.get_subscriber!(id),
         {:can, true} <- {:can, can?(claims, view(subscriber))} do
      render(conn, "show.json", subscriber: subscriber)
    end
  end

  def delete(conn, %{"id" => id}) do
    with claims <- conn.assigns[:current_resource],
         subscriber <- Subscribers.get_subscriber!(id),
         {:can, true} <- {:can, can?(claims, delete(subscriber))},
         {:ok, _} <- Subscribers.delete_subscriber(subscriber) do
      send_resp(conn, :no_content, "")
    end
  end
end
