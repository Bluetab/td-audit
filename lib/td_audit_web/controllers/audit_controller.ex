defmodule TdAuditWeb.AuditController do
  use TdAuditWeb, :controller
  require Logger

  alias TdAudit.Audit.Event
  alias TdAudit.CommonSearch

  @td_queue Application.get_env(:td_audit, :queue)

  def create(conn, %{"audit" => audit_params}) do
    changeset = Event.changeset(%Event{}, audit_params)
    case changeset.valid? do
      true ->
        conn
        |> enqueue(audit_params)
      false ->
        Logger.info  "audit controller invalid params: #{inspect(audit_params)}"
        Logger.info  "autdit controller changeset: #{inspect(changeset)}"
        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(:unprocessable_entity, Poison.encode!(%{"errors": "Invalid params"}))
    end
  end

  defp enqueue(conn, audit_params) do
    case @td_queue.enqueue("timeline", TdAudit.SendEventWorker, audit_params) do
      {:ok, jid} ->
        CommonSearch.update_search_on_event(audit_params)
        conn
        |> put_status(:created)
        |> send_resp(:created, Poison.encode!(%{"job_id": jid}))
      {:error, error} ->
        Logger.info "audit controller queue fails: #{inspect(audit_params)}"
        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(:unprocessable_entity, Poison.encode!(%{"errors": error}))
    end
  end
end
