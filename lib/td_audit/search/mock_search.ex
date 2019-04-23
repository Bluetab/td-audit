defmodule TdAudit.Search.MockSearch do
  @moduledoc false

  def update_by_query(_index_name, query), do: query
end
