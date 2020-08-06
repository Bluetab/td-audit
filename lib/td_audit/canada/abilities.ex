defmodule TdAudit.Canada.Abilities do
  @moduledoc """
  Permissions for Audit operations
  """

  alias TdAudit.Accounts.User
  alias TdAudit.Subscriptions.Subscription

  defimpl Canada.Can, for: User do
    def can?(%User{is_admin: true}, _action, _domain), do: true

    def can?(%User{id: id}, :create, %{"subscription" => %{"subscriber" => %{"type" => "user", "identifier" => identifier}}}) do
      id == identifier
    end

    def can?(%User{id: id}, :update, %{"subscription" => %{"subscriber" => %{"type" => "user", "identifier" => identifier}} }) do
      id == identifier
    end

    def can?(%User{}, _action, _entity), do: false
  end
end
