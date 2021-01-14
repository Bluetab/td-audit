defmodule TdAudit.Canada.Abilities do
  @moduledoc """
  Permissions for Audit operations
  """

  alias TdAudit.Auth.Claims
  alias TdAudit.Subscriptions.Subscriber
  alias TdAudit.Subscriptions.Subscription

  defimpl Canada.Can, for: Claims do
    def can?(%Claims{is_admin: true}, _action, _domain), do: true

    def can?(%Claims{user_id: user_id}, :create, %{"type" => "user", "identifier" => identifier}) do
      to_string(user_id) == to_string(identifier)
    end

    def can?(%Claims{user_id: user_id}, :update, %Subscription{
          subscriber: %Subscriber{identifier: identifier, type: "user"}
        }) do
      to_string(user_id) == to_string(identifier)
    end

    def can?(%Claims{user_id: user_id}, :delete, %Subscription{
          subscriber: %Subscriber{identifier: identifier, type: "user"}
        }) do
      to_string(user_id) == to_string(identifier)
    end

    def can?(%Claims{}, _action, _entity), do: false
  end
end
