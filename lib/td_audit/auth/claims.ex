defmodule TdAudit.Auth.Claims do
  @moduledoc """
  Jason web tokens (JWTs) contain claims which are pieces of information
  asserted about a subject. This module provides a struct containing the claims
  that are used by Truedat.
  """

  @typedoc "The claims of an authenticated user"
  @type t :: %__MODULE__{
          user_id: non_neg_integer() | nil,
          user_name: binary() | nil,
          role: binary() | nil,
          is_admin: boolean(),
          jti: binary() | nil
        }

  @derive {Jason.Encoder, only: [:user_id, :user_name]}
  defstruct [:user_id, :user_name, :role, :jti, is_admin: false]
end
