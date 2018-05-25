defmodule TdAudit.Audit.Event do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :event, :string
    field :payload, :map
    field :resource_id, :integer
    field :resource_type, :string
    field :service, :string
    field :ts, :utc_datetime
    field :user_id, :integer
    field :user_name, :string

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:service, :resource_id, :resource_type, :event, :payload, :user_id, :user_name, :ts])
    |> validate_required([:service, :resource_id, :resource_type, :event, :payload, :user_id, :user_name, :ts])
  end
end
