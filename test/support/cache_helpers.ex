defmodule CacheHelpers do
  @moduledoc """
  Helper functions for loading and cleaning test fixtures in cache
  """

  import ExUnit.Callbacks, only: [on_exit: 1]
  import TdAudit.Factory

  alias TdCache.AclCache
  alias TdCache.ConceptCache
  alias TdCache.TaxonomyCache
  alias TdCache.UserCache

  def put_acl_role_users(domain_id, role, users_or_user_ids) do
    user_ids =
      Enum.map(users_or_user_ids, fn
        %{id: id} -> id
        id when is_integer(id) -> id
      end)

    on_exit(fn ->
      AclCache.delete_acl_roles("domain", domain_id)
      AclCache.delete_acl_role_users("domain", domain_id, role)
    end)

    AclCache.set_acl_role_users("domain", domain_id, role, user_ids)
  end

  def put_domain(params \\ %{})

  def put_domain(%{id: id} = domain) do
    on_exit(fn -> TaxonomyCache.delete_domain(id, clean: true) end)
    {:ok, _} = TaxonomyCache.put_domain(domain)
    domain
  end

  def put_domain(params) do
    :domain
    |> build(params)
    |> put_domain()
  end

  def put_user(params \\ %{})

  def put_user(%{id: id} = user) do
    on_exit(fn -> UserCache.delete(id) end)
    {:ok, _} = UserCache.put(user)
    user
  end

  def put_user(params) do
    :user
    |> build(params)
    |> put_user()
  end

  def put_concept(params \\ %{})

  def put_concept(%{id: id} = concept) do
    on_exit(fn -> ConceptCache.delete(id) end)
    {:ok, _} = ConceptCache.put(concept)
    concept
  end

  def put_concept(params) do
    :concept
    |> build(params)
    |> put_concept()
  end
end
