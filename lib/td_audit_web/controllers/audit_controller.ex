defmodule TdAuditWeb.AuditController do
  use TdAuditWeb, :controller

  alias TdAudit.Audit.Event

  @td_queue Application.get_env(:td_audit, :queue)

  def create(conn, %{"audit" => audit_params}) do
    changeset = Event.changeset(%Event{}, audit_params)

    case changeset.valid? do
      true ->
        conn
        |> enqueue(audit_params)
      false ->
        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(:unprocessable_entity, Poison.encode!(%{"errors": "Invalid params"}))
    end
  end

  defp enqueue(conn, audit_params) do
    case @td_queue.enqueue("timeline", TdAudit.SendEventWorker, audit_params) do
      {:ok, jid} ->
        conn
        |> put_status(:created)
        |> send_resp(:created, Poison.encode!(%{"job_id": jid}))
      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(:unprocessable_entity, Poison.encode!(%{"errors": error}))
    end
  end
end
