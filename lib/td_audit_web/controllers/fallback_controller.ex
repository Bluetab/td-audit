defmodule TdAuditWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use TdAuditWeb, :controller

  def call(conn, {:can, false}) do
    conn
    |> put_status(:forbidden)
    |> put_view(TdAuditWeb.ErrorView)
    |> render("403.json")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(TdAuditWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(TdAuditWeb.ErrorView)
    |> render("404.json")
  end
end
