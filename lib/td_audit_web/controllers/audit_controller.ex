defmodule TdAuditWeb.AuditController do
  use TdAuditWeb, :controller

  alias TdAudit.Audit.Event

  @td_queue Application.get_env(:td_audit, :queue)

  def create(conn, %{"audit" => audit_params}) do
    changeset = Event.changeset(%Event{}, audit_params)

    case changeset.valid? do
      true ->
        @td_queue.enqueue("timeline", TdAudit.SendEventWorker, audit_params)
        conn
        |> put_status(:created)
        |> send_resp(:no_content, "")
      false ->
        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(:unprocessable_entity, "Invalid params")
    end
  end
end
