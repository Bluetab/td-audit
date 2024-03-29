defmodule TdAudit.Subscriptions.Scope do
  @moduledoc """
  Ecto Schema module for subscription scope.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias TdAudit.Subscriptions.Filters

  @valid_rule_result_statuses ["fail", "success", "warn", "error", "empty_dataset"]
  @valid_jobs_statuses [
    "job_status_started",
    "job_status_pending",
    "job_status_failed",
    "job_status_succeeded",
    "job_status_warning",
    "job_status_info"
  ]

  @valid_implementation_statuses [
    "draft",
    "pending_approval",
    "rejected",
    "published",
    "versioned",
    "deprecated"
  ]

  @primary_key false

  embedded_schema do
    field(:events, {:array, :string})
    field(:status, {:array, :string})
    field(:resource_name, :string)
    field(:resource_type, :string)
    field(:resource_id, :integer)
    field(:domain_id, :integer)
    embeds_one(:filters, Filters, on_replace: :delete)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = scope, %{} = params) do
    scope
    |> cast(params, [:domain_id, :events, :resource_name, :resource_type, :resource_id])
    |> common_changeset(params)
  end

  def update_changeset(%__MODULE__{} = scope, %{} = params) do
    scope
    |> cast(params, [:events])
    |> common_changeset(params)
  end

  defp common_changeset(changeset, params) do
    changeset
    |> validate_length(:events, min: 1)
    |> validate_inclusion(:resource_type, [
      "data_structure",
      "domain",
      "domains",
      "ingest",
      "concept",
      "rule",
      "source",
      "implementation"
    ])
    |> validate_required([:events, :resource_type, :resource_id])
    |> update_change(:events, &sort_uniq/1)
    |> validate_status(params)
    |> cast_embed(:filters, with: &Filters.changeset/2)
  end

  defp validate_status(%Changeset{} = changeset, %{} = params) do
    case get_field(changeset, :events) do
      ["rule_result_created"] ->
        validate_status_changeset(changeset, params, @valid_rule_result_statuses)

      ["implementation_status_updated"] ->
        validate_status_changeset(changeset, params, @valid_implementation_statuses)

      ["status_changed"] ->
        validate_status_changeset(changeset, params, @valid_jobs_statuses)

      _ ->
        changeset
    end
  end

  defp validate_status_changeset(changeset, params, valid_statuses) do
    changeset
    |> cast(params, [:status])
    |> validate_required(:status)
    |> update_change(:status, &sort_uniq/1)
    |> validate_length(:status, min: 1)
    |> validate_change(:status, fn _, status ->
      status_validator(status, valid_statuses)
    end)
  end

  defp status_validator(status, valid_statuses) do
    if Enum.all?(status, &Enum.member?(valid_statuses, &1)) do
      []
    else
      [status: {"is invalid", [validation: :inclusion, enum: valid_statuses]}]
    end
  end

  defp sort_uniq(enumerable) do
    enumerable
    |> Enum.sort()
    |> Enum.uniq()
  end
end
