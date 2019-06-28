defmodule TdAudit.Accounts.User do
  @moduledoc false

  @derive Jason.Encoder
  defstruct id: 0, user_name: nil, is_admin: false

  def gen_id_from_user_name(user_name) do
    Integer.mod(:binary.decode_unsigned(user_name), 100_000)
  end
end
