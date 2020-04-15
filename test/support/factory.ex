defmodule TdAudit.Factory do
  @moduledoc """
  Factory methods for tests
  """

  use ExMachina.Ecto, repo: TdAudit.Repo

  alias TdAudit.Subscriptions.Subscription

  def concept_factory do
    %{
      id: sequence(:concept_id, & &1 + 123_456_789),
      name: sequence(:concept_name, &"Concept #{&1}"),
      content: %{}
    }
  end

  def user_factory do
    %{
      id: sequence(:user_id, & &1 + 123_456_789),
      email: sequence(:email, &"username_#{&1}@example.com"),
      user_name: sequence(:user_name, &"username_#{&1}"),
      full_name: sequence(:user_full_name, &"User #{&1}"),
      is_admin: false
    }
  end

  def subscription_factory do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    %Subscription{
      event: "create_comment",
      resource_type: "business_concept",
      resource_id: sequence(:subscription_resource_id, & &1 + 1),
      user_email: sequence(:subscription_email, &"username_#{&1}@example.com"),
      periodicity: "daily",
      last_consumed_event: now
    }
  end
end
