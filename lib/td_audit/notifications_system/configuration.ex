defmodule TdAudit.NotificationsSystem.Configuration do
  @moduledoc """
  Entity representing a configuration rule of the notifications
  System
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications_system_configuration" do
    field :settings, :map
    field :event, :string

    timestamps()
  end

  @valid_settings_keys ["generate_subscription", "generate_notification"]
  @valid_keys_in_settings %{
    "generate_subscription" => ["roles"],
    "generate_notification" => ["active"]
  }

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:event, :settings])
    |> validate_required([:event, :settings])
    |> validate_settings_keys()
    |> validate_keys_in_settings()
  end

  defp validate_settings_keys(changeset) do
    case changeset.valid? do
      true ->
          changeset
          |> get_field(:settings)
          |> is_settings_format_valid?()
          |> return_changeset(changeset, "invalid.param")

      false -> changeset
    end
  end

  defp validate_keys_in_settings(changeset) do
    case changeset.valid? do
      true ->
        settings =
          changeset
          |> get_field(:settings)

          settings
          |> Map.keys()
          |> are_keys_in_settings_valid?(settings)
          |> return_changeset(changeset, "invalid.param")

        false -> changeset
    end
  end

  defp is_settings_format_valid?(settings) do
      Map.keys(settings)
      validations_list =
        Enum.map(
          Map.keys(settings),
          fn el -> {Enum.any?(@valid_settings_keys, &(el == &1)), el}
          end)

      Enum.find(validations_list, true, &find_element_in_validation_list(&1))
  end

  defp are_keys_in_settings_valid?([], _), do: true
  defp are_keys_in_settings_valid?(keys_in_settings, settings) do
    validations_list =
      Enum.map(
        keys_in_settings,
        &is_key_in_settings_valid?(&1, Map.get(settings, &1))
      )

      Enum.find(validations_list, true, &find_element_in_validation_list(&1))
  end

  defp is_key_in_settings_valid?(parent_key, value) do
    valid_keys = Map.get(@valid_keys_in_settings, parent_key)
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
    changeset |> add_error(:settings, message <> "." <> field)
  end
end
