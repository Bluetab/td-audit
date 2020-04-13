defmodule TdAuditWeb.AuditController do
  use TdAuditWeb, :controller

  alias Jason, as: JSON
  alias TdAudit.Audit.Event

  require Logger

  @td_queue Application.get_env(:td_audit, :queue)

  def create(conn, %{"audit" => audit_params}) do
    changeset = Event.changeset(%Event{}, audit_params)

    case changeset.valid? do
      true ->
        enqueue(conn, audit_params)

      false ->
        Logger.info("audit controller invalid params: #{inspect(audit_params)}")
        Logger.info("audit controller changeset: #{inspect(changeset)}")

        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(:unprocessable_entity, JSON.encode!(%{errors: "Invalid params"}))
    end
  end

  defp enqueue(conn, audit_params) do
    case @td_queue.enqueue("timeline", TdAudit.SendEventWorker, audit_params) do
      {:ok, jid} ->
        conn
        |> put_status(:created)
        |> send_resp(:created, JSON.encode!(%{job_id: jid}))

      {:error, error} ->
        Logger.info("audit controller queue fails: #{inspect(audit_params)}")

        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(:unprocessable_entity, JSON.encode!(%{errors: error}))
    end
  end
end
