defmodule TdAudit.Audit.Event do
  @moduledoc """
  Ecto Schema module for audit events.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "events" do
    field(:event, :string)
    field(:payload, :map)
    field(:resource_id, :integer)
    field(:resource_type, :string)
    field(:service, :string)
    field(:ts, :utc_datetime_usec)
    field(:user_id, :integer)
    field(:user_name, :string)
    field(:user, :map, virtual: true)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = event, params) do
    event
    |> cast(params, [
      :service,
      :resource_id,
      :resource_type,
      :event,
      :user_id,
      :user_name,
      :ts
    ])
    |> put_payload(params)
    |> validate_required([
      :service,
      :event,
      :payload,
      :ts
    ])
    |> validate_user_and_resource()
    |> update_change(:resource_type, &update_resource_type/1)
  end

  defp validate_user_and_resource(changeset) do
    case get_field(changeset, :event) do
      "login_attempt" -> changeset
      "share_document" -> changeset
      "external_notification" -> changeset
      _ -> validate_required(changeset, [:user_id, :resource_type, :resource_id])
    end
  end

  defp update_resource_type("business_concept"), do: "concept"
  defp update_resource_type(value), do: value

  defp put_payload(changeset, %{payload: payload} = params) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, value} -> put_change(changeset, :payload, value)
      _ -> cast(changeset, params, [:payload])
    end
  end

  defp put_payload(changeset, params), do: cast(changeset, params, [:payload])
end
