defmodule TdAudit.Subscriptions.FiltersTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias TdAudit.Subscriptions.Filters

  describe "changeset/2" do
    test "validates required fields" do
      params = %{template: %{"id" => 1}}

      assert %{errors: [content: {"can't be blank", [validation: :required]}]} =
               Filters.changeset(params)

      params = %{content: %{"name" => "foo", "value" => "bar"}}

      assert %{errors: [template: {"can't be blank", [validation: :required]}]} =
               Filters.changeset(params)

      params = %{template: %{"id" => 1}, content: %{"name" => "foo", "value" => "bar"}}
      assert %Changeset{valid?: true} = Filters.changeset(params)
    end

    test "validates field format" do
      params = %{template: %{"id" => 1}, content: %{"name" => "foo", "value" => "bar"}}
      assert %Changeset{valid?: true} = Filters.changeset(params)

      params = %{template: %{"id" => 1}, content: %{"foo" => "bar"}}

      assert %{errors: [content: {"expected a map with name and value", [validation: :format]}]} =
               Filters.changeset(params)

      params = %{template: %{"foo" => "bar"}, content: %{"name" => "foo", "value" => "bar"}}

      assert %{errors: [template: {"expected a map with template id", [validation: :format]}]} =
               Filters.changeset(params)
    end
  end
end
