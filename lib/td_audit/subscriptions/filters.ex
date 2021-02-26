defmodule TdAudit.Subscriptions.Filters do
  @moduledoc """
  Ecto Schema module for subscription filters.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:template, :map)
    field(:content, :map)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = filters, %{} = params) do
    filters
    |> cast(params, [:template, :content])
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    |> validate_required([:template, :content])
    |> validate_change(:template, &template/2)
    |> validate_change(:content, &content/2)
  end

  defp template(:template, template) do
    case Map.has_key?(template, "id") do
      true -> []
      false -> [template: {"expected a map with template id", [validation: :format]}]
    end
  end

  defp content(:content, content) do
    case Map.has_key?(content, "name") && Map.has_key?(content, "value") do
      true -> []
      false -> [content: {"expected a map with name and value", [validation: :format]}]
    end
  end
end
