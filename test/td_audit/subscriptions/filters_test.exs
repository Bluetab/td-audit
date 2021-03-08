defmodule TdAudit.Subscriptions.FiltersTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias TdAudit.Subscriptions.Filters
  alias TdCache.TemplateCache

  describe "changeset/2" do
    setup do
      template_id = System.unique_integer([:positive])

      content = [
        %{
          "name" => "group",
          "fields" => [
            %{
              name: "foo",
              type: "string",
              cardinality: "?",
              values: %{"fixed" => ["bar"]},
              subscribable: true
            },
            %{
              name: "xyz",
              type: "string",
              cardinality: "?",
              values: %{"fixed_tuple" => [%{"value" => "foo", "text" => "Foo"}]},
              subscribable: true
            }
          ]
        }
      ]

      template = %{
        id: template_id,
        name: "foo",
        label: "label",
        scope: "test",
        content: content,
        updated_at: DateTime.utc_now()
      }

      TemplateCache.put(template)

      on_exit(fn ->
        TemplateCache.delete(template_id)
      end)

      {:ok, [template: template]}
    end

    test "validates required fields", %{template: %{id: id}} do
      params = %{template: %{"id" => id}}

      assert %{errors: [content: {"can't be blank", [validation: :required]}]} =
               Filters.changeset(params)

      params = %{content: %{"name" => "foo", "value" => "bar"}}

      assert %{errors: [template: {"can't be blank", [validation: :required]}]} =
               Filters.changeset(params)

      params = %{template: %{"id" => id}, content: %{"name" => "foo", "value" => "bar"}}
      assert %Changeset{valid?: true} = Filters.changeset(params)
    end

    test "validates field format", %{template: %{id: id}} do
      params = %{template: %{"id" => id}, content: %{"name" => "foo", "value" => "bar"}}
      assert %Changeset{valid?: true} = Filters.changeset(params)

      params = %{template: %{"id" => id}, content: %{"foo" => "bar"}}

      assert %{errors: [content: {"expected a map with name and value", [validation: :format]}]} =
               Filters.changeset(params)

      params = %{template: %{"foo" => "bar"}, content: %{"name" => "foo", "value" => "bar"}}

      assert %{errors: [template: {"expected a map with template id", [validation: :format]}]} =
               Filters.changeset(params)
    end

    test "validates template fields", %{template: %{id: id}} do
      params = %{
        template: %{"id" => System.unique_integer([:positive])},
        content: %{"name" => "foo", "value" => "bar"}
      }

      assert %Changeset{
               valid?: false,
               errors: [template: {"missing template", [validation: :required]}]
             } = Filters.changeset(params)

      params = %{
        template: %{"id" => id},
        content: %{"name" => "baz", "value" => "bar"}
      }

      assert %Changeset{
               valid?: false,
               errors: [baz: {"missing field on template", [validation: :required]}]
             } = Filters.changeset(params)

      params = %{
        template: %{"id" => id},
        content: %{"name" => "foo", "value" => "xyz"}
      }

      assert %Changeset{
               valid?: false,
               errors: [foo: {"missing value in fixed template field", [validation: :required]}]
             } = Filters.changeset(params)

      params = %{
        template: %{"id" => id},
        content: %{"name" => "xyz", "value" => "bar"}
      }

      assert %Changeset{
               valid?: false,
               errors: [
                 xyz: {"missing value in fixed tuple template field", [validation: :required]}
               ]
             } = Filters.changeset(params)

      params = %{template: %{"id" => id}, content: %{"name" => "foo", "value" => "bar"}}
      assert %Changeset{valid?: true} = Filters.changeset(params)

      params = %{template: %{"id" => id}, content: %{"name" => "xyz", "value" => "foo"}}
      assert %Changeset{valid?: true} = Filters.changeset(params)
    end
  end
end
