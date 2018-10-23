defmodule TdPerms.UserCacheMock do
  @moduledoc """
  This mock generates fake user in order to be consumed by the modules
  importing UserCache
  """
  use Agent
  alias Poision

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: :MockUserCache)
  end

  def get_user(user_id) do
    Agent.get(:MockUserCache, & &1)
    |> Enum.find(&(Map.get(&1, "id") == user_id))
    |> Map.take(["user_name", "full_name", "email"])
  end

  def put_user_in_cache(user) do
    Agent.update(:MockUserCache, &[user | &1])
  end
end
