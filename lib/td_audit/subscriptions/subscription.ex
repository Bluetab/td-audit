defmodule TdAudit.Subscriptions.Subscription do
  @moduledoc """
  Ecto Schema module for Subscriptions.
  """
  import Ecto.Changeset

  use Ecto.Schema

  alias TdAudit.Subscriptions.Scope
  alias TdAudit.Subscriptions.Subscriber

  schema "subscriptions" do
    field(:periodicity, :string)
    field(:last_event_id, :integer)

    embeds_one(:scope, Scope, on_replace: :delete)

    belongs_to(:subscriber, Subscriber)

    timestamps()
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = subscription, attrs) do
    subscription
    |> cast(attrs, [:periodicity, :last_event_id])
    |> cast_embed(:scope, with: &Scope.changeset/2)
    |> validate_subscription()
  end

  def update_changeset(%__MODULE__{} = subscription, attrs) do
    subscription
    |> cast(attrs, [:periodicity])
    |> cast_embed(:scope, with: &Scope.update_changeset/2)
    |> validate_subscription()
  end

  defp validate_subscription(changeset) do
    changeset
    |> validate_required([:scope, :periodicity, :last_event_id])
    |> validate_inclusion(:periodicity, ["daily", "minutely", "hourly"])
    |> unique_constraint([:scope, :subscriber_id])
  end
end
