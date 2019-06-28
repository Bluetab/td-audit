defmodule TdAudit.Accounts.User do
  @moduledoc false

  @derive {Jason.Encoder, only: [:id, :is_admin, :user_name]}
  defstruct id: 0,
            user_name: nil,
            password: nil,
            is_admin: false,
            email: nil,
            full_name: nil,
            groups: []

  def gen_id_from_user_name(user_name) do
    Integer.mod(:binary.decode_unsigned(user_name), 100_000)
  end
end
