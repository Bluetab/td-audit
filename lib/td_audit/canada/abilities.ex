defmodule TdAudit.Canada.Abilities do
  @moduledoc """
  Permissions for Audit operations
  """

  alias TdAudit.Accounts.User
  alias TdAudit.Subscriptions.Subscriber
  alias TdAudit.Subscriptions.Subscription

  defimpl Canada.Can, for: User do
    def can?(%User{is_admin: true}, _action, _domain), do: true

    def can?(%User{id: id}, :create, %{"type" => "user", "identifier" => identifier}) do
      to_string(id) == to_string(identifier)
    end

    def can?(%User{id: id}, :update, %Subscription{
          subscriber: %Subscriber{identifier: identifier, type: "user"}
        }) do
      to_string(id) == to_string(identifier)
    end

    def can?(%User{id: id}, :delete, %Subscription{
          subscriber: %Subscriber{identifier: identifier, type: "user"}
        }) do
      to_string(id) == to_string(identifier)
    end

    def can?(%User{}, _action, _entity), do: false
  end
end
