defmodule TdAudit.Subscriptions.SubscriptionTest do
  use TdAudit.DataCase

  alias Ecto.Changeset
  alias TdAudit.Subscriptions.Subscription

  describe "changeset/2" do
    test "validates scope is present" do
      params = %{}
      assert %{errors: errors} = Subscription.changeset(params)
      assert {"can't be blank", [validation: :required]} = errors[:scope]
    end

    test "validates scope using Scope.changeset/2" do
      params = %{scope: %{"foo" => 42}}

      assert %{scope: scope_errors} =
               params
               |> Subscription.changeset()
               |> Changeset.traverse_errors(& &1)

      assert %{events: [{"can't be blank", [validation: :required]}]} = scope_errors
    end

    test "includes resource_name and domain_id in scope Scope.changeset/2" do
      %{
        last_event_id: last_event_id,
        periodicity: periodicity,
        scope: %{
          "resource_id" => resource_id,
          "resource_name" => resource_name,
          "resource_type" => resource_type,
          "events" => events,
          "domain_id" => domain_id
        }
      } =
        params = %{
          scope: %{
            "resource_id" => 42,
            "resource_name" => "bar",
            "resource_type" => "data_structure",
            "events" => ["foo"],
            "domain_id" => 1
          },
          periodicity: "hourly",
          last_event_id: 0
        }

      %{
        valid?: true,
        changes: %{
          last_event_id: ^last_event_id,
          periodicity: ^periodicity,
          scope: %{
            changes: %{
              events: ^events,
              resource_id: ^resource_id,
              resource_name: ^resource_name,
              resource_type: ^resource_type,
              domain_id: ^domain_id
            }
          }
        }
      } = Subscription.changeset(params)
    end
  end
end
