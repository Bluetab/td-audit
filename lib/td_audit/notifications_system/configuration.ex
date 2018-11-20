defmodule TdAudit.NotificationsSystem.Configuration do
  @moduledoc """
  Entity representing a configuration rule of the notifications
  System
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications_system_configuration" do
    field :configuration, :map
    field :event, :string

    timestamps()
  end

  @valid_configuration_keys ["generate_subscription", "generate_notification"]
  @valid_keys_in_configuration %{
    "generate_subscription" => ["roles"],
    "generate_notification" => ["active"]
  }

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:event, :configuration])
    |> validate_required([:event, :configuration])
    |> validate_configuration_keys()
    |> validate_keys_in_configuration()
  end

  defp validate_configuration_keys(changeset) do
    case changeset.valid? do
      true ->
          changeset
          |> get_field(:configuration)
          |> is_configuration_format_valid?()
          |> return_changeset(changeset, "invalid.param")

      false -> changeset
    end
  end

  defp validate_keys_in_configuration(changeset) do
    case changeset.valid? do
      true ->
        configuration =
          changeset
          |> get_field(:configuration)

        configuration
          |> Map.keys()
          |> are_keys_in_configuration_valid?(configuration)
          |> return_changeset(changeset, "invalid.param")

        false -> changeset
    end
  end

  defp is_configuration_format_valid?(configuration) do
      Map.keys(configuration)
      validations_list =
        Enum.map(
          Map.keys(configuration),
          fn el -> {Enum.any?(@valid_configuration_keys, &(el == &1)), el}
          end)

      Enum.find(validations_list, true, &find_element_in_validation_list(&1))
  end

  defp are_keys_in_configuration_valid?([], _), do: true
  defp are_keys_in_configuration_valid?(keys_in_configuration, configuration) do
    validations_list =
      Enum.map(
        keys_in_configuration,
        &is_key_in_configuration_valid?(&1, Map.get(configuration, &1))
      )

      Enum.find(validations_list, true, &find_element_in_validation_list(&1))
  end

  defp is_key_in_configuration_valid?(parent_key, value) do
    valid_keys = Map.get(@valid_keys_in_configuration, parent_key)
    validations_list =
      value
        |> Map.keys()
        |> Enum.map(fn k ->
          {Enum.any?(valid_keys, &(k == &1)), parent_key <> "." <> k}
        end
        )

    Enum.find(validations_list, true, &find_element_in_validation_list(&1))
  end

  defp find_element_in_validation_list({bv, _}), do: bv == false
  defp find_element_in_validation_list(_), do: false

  defp return_changeset(true, changeset, _), do: changeset
  defp return_changeset({false, field}, changeset, message) do
    changeset |> add_error(:configuration, message <> "." <> field)
  end
end
