defmodule TdAudit.Subscriptions.Filters do
  @moduledoc """
  Ecto Schema module for subscription filters.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias TdCache.TemplateCache
  alias TdDfLib.Format

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
    |> validate_content()
  end

  defp template(:template, %{"id" => id}) do
    id
    |> TemplateCache.get()
    |> case do
      {:ok, nil} ->
        [template: {"missing template", [validation: :required]}]

      _ ->
        []
    end
  end

  defp template(:template, _tempate),
    do: [template: {"expected a map with template id", [validation: :format]}]

  defp validate_content(%Changeset{valid?: true} = changeset) do
    validate_change(changeset, :content, fn _, content -> content(content, changeset) end)
  end

  defp validate_content(changeset), do: changeset

  defp content(content, %Changeset{valid?: true} = changeset) do
    content_schema =
      changeset
      |> get_field(:template)
      |> Map.get("id")
      |> TemplateCache.get()
      |> case do
        {:ok, %{} = template} -> template
        _ -> %{}
      end
      |> Map.get(:content, [])
      |> Format.flatten_content_fields()

    case Map.has_key?(content, "name") && Map.has_key?(content, "value") do
      true ->
        %{"name" => name, "value" => value} = Map.take(content, ["name", "value"])

        content_schema
        |> Enum.find(fn %{"name" => field} -> field == name end)
        |> do_valid_content(name, value)

      false ->
        [content: {"expected a map with name and value", [validation: :format]}]
    end
  end

  defp do_valid_content(nil, name, _value),
    do:
      Keyword.new([{String.to_atom(name), {"missing field on template", [validation: :required]}}])

  defp do_valid_content(%{"values" => %{"fixed" => values}}, name, value) do
    case value in values do
      true ->
        []

      _ ->
        Keyword.new([
          {String.to_atom(name),
           {"missing value in fixed template field", [validation: :required]}}
        ])
    end
  end

  defp do_valid_content(%{"values" => %{"fixed_tuple" => values}}, name, value) do
    tuple_values = Enum.map(values, &Map.get(&1, "value"))

    case value in tuple_values do
      true ->
        []

      _ ->
        Keyword.new([
          {String.to_atom(name),
           {"missing value in fixed tuple template field", [validation: :required]}}
        ])
    end
  end

  defp do_valid_content(_field, name, _value),
    do: Keyword.new([{String.to_atom(name), {"invalid field format", [validation: :format]}}])
end
