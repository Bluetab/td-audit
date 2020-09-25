defmodule TdAudit.Subscriptions.Scope do
  @moduledoc """
  Ecto Schema module for subscription scope.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:events, {:array, :string})
    field(:status, {:array, :string})
    field(:resource_type, :string)
    field(:resource_id, :integer)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = scope, %{} = params) do
    scope
    |> cast(params, [:events, :resource_type, :resource_id])
    |> validate_length(:events, min: 1)
    |> validate_inclusion(:resource_type, ["domain", "domains", "ingest", "concept", "rule"])
    |> validate_required([:events, :resource_type, :resource_id])
    |> update_change(:events, &sort_uniq/1)
    |> validate_status(params)
  end

  defp validate_status(%Changeset{} = changeset, %{} = params) do
    case get_field(changeset, :events) do
      ["rule_result_created"] ->
        changeset
        |> cast(params, [:status])
        |> validate_required(:status)
        |> update_change(:status, &sort_uniq/1)
        |> validate_length(:status, min: 1)
        |> validate_change(:status, &status_validator/2)

      _ ->
        changeset
    end
  end

  defp status_validator(:status, status) do
    status
    |> Enum.all?(&Enum.member?(["fail", "success", "warn"], &1))
    |> case do
      true -> []
      _ -> [status: {"is invalid", [validation: :inclusion, enum: ["fail", "success", "warn"]]}]
    end
  end

  defp sort_uniq(enumerable) do
    enumerable
    |> Enum.sort()
    |> Enum.uniq()
  end
end