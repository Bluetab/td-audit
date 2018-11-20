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

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:event, :configuration])
    |> validate_required([:event, :configuration])
  end
end
