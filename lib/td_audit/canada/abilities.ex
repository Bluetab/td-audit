defmodule TdAudit.Canada.Abilities do
  @moduledoc """
  Permissions for Audit operations
  """

  alias TdAudit.Auth.Session
  alias TdAudit.Subscriptions.Subscriber
  alias TdAudit.Subscriptions.Subscription

  defimpl Canada.Can, for: Session do
    def can?(%Session{is_admin: true}, _action, _domain), do: true

    def can?(%Session{user_id: user_id}, :create, %{"type" => "user", "identifier" => identifier}) do
      to_string(user_id) == to_string(identifier)
    end

    def can?(%Session{user_id: user_id}, :update, %Subscription{
          subscriber: %Subscriber{identifier: identifier, type: "user"}
        }) do
      to_string(user_id) == to_string(identifier)
    end

    def can?(%Session{user_id: user_id}, :delete, %Subscription{
          subscriber: %Subscriber{identifier: identifier, type: "user"}
        }) do
      to_string(user_id) == to_string(identifier)
    end

    def can?(%Session{}, _action, _entity), do: false
  end
end
