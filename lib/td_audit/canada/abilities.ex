defmodule TdAudit.Canada.Abilities do
  @moduledoc """
  Permissions for Audit operations
  """

  alias TdAudit.Accounts.User

  defimpl Canada.Can, for: User do
    def can?(%User{is_admin: true}, _action, _domain), do: true
    def can?(%User{}, _action, _entity), do: false
  end
end
