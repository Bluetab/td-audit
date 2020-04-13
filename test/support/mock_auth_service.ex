defmodule TdAuditWeb.ApiServices.MockAuthService do
  @moduledoc false

  use Agent

  alias TdAudit.Accounts.User

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: MockAuthService)
  end

  def set_users(user_list) do
    Agent.update(MockAuthService, fn _ -> user_list end)
  end

  def create_user(%{"user" => %{user_name: user_name, is_admin: is_admin}}) do
    new_user = %User{
      id: User.gen_id_from_user_name(user_name),
      user_name: user_name,
      is_admin: is_admin
    }

    Agent.update(MockAuthService, &(&1 ++ [new_user]))
    new_user
  end


  def index do
    Agent.get(MockAuthService, & &1) || []
  end
end
