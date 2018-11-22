defmodule TdPerms.BusinessConceptCacheMock do
  @moduledoc """
  This mock generates fake user in order to be consumed by the modules
  importing BusinessConceptCache
  """
  use Agent
  alias Poision

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: :MockBusinessConceptCache)
  end

  def get_name(bc_id) do
    Agent.get(:MockBusinessConceptCache, & &1)
    |> Enum.find(&(Map.get(&1, "id") == bc_id))
    |> Map.get("name")
  end

  def get_business_concept_version_id(bc_id) do
    Agent.get(:MockBusinessConceptCache, & &1)
    |> Enum.find(&(Map.get(&1, "id") == bc_id))
    |> Map.get("business_concept_version_id")
  end

  def put_bc_in_cache(business_concept) do
    Agent.update(:MockBusinessConceptCache, &[business_concept | &1])
  end
end
