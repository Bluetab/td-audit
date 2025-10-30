defmodule TdAudit.Map.HelpersTest do
  use ExUnit.Case

  alias TdAudit.Map.Helpers

  describe "underscore_keys/1" do
    test "converts camelCase keys to underscore_keys" do
      input = %{"firstName" => "John", "lastName" => "Doe"}
      expected = %{"first_name" => "John", "last_name" => "Doe"}

      assert Helpers.underscore_keys(input) == expected
    end

    test "handles nested maps" do
      input = %{"user" => %{"firstName" => "John", "lastName" => "Doe"}}
      expected = %{"user" => %{"first_name" => "John", "last_name" => "Doe"}}

      assert Helpers.underscore_keys(input) == expected
    end

    test "handles lists of maps" do
      input = [%{"firstName" => "John"}, %{"lastName" => "Doe"}]
      expected = [%{"first_name" => "John"}, %{"last_name" => "Doe"}]

      assert Helpers.underscore_keys(input) == expected
    end

    test "handles nil input" do
      assert Helpers.underscore_keys(nil) == nil
    end

    test "handles non-map values" do
      assert Helpers.underscore_keys("string") == "string"
      assert Helpers.underscore_keys(123) == 123
    end

    test "replaces hyphens with underscores" do
      input = %{"first-name" => "John"}
      expected = %{"first_name" => "John"}

      assert Helpers.underscore_keys(input) == expected
    end
  end

  describe "atomize_keys/1" do
    test "converts string keys to atom keys" do
      input = %{"name" => "John", "age" => 30}
      expected = %{name: "John", age: 30}

      assert Helpers.atomize_keys(input) == expected
    end

    test "handles nested maps" do
      input = %{"user" => %{"name" => "John", "age" => 30}}
      expected = %{user: %{name: "John", age: 30}}

      assert Helpers.atomize_keys(input) == expected
    end

    test "handles lists of maps" do
      input = [%{"name" => "John"}, %{"age" => 30}]
      expected = [%{name: "John"}, %{age: 30}]

      assert Helpers.atomize_keys(input) == expected
    end

    test "handles nil input" do
      assert Helpers.atomize_keys(nil) == nil
    end

    test "handles structs" do
      struct = %{__struct__: SomeStruct, field: "value"}
      assert Helpers.atomize_keys(struct) == struct
    end

    test "handles non-map values" do
      assert Helpers.atomize_keys("string") == "string"
      assert Helpers.atomize_keys(123) == 123
    end
  end

  describe "stringify_keys/1" do
    test "converts atom keys to string keys" do
      input = %{name: "John", age: 30}
      expected = %{"name" => "John", "age" => 30}

      assert Helpers.stringify_keys(input) == expected
    end

    test "handles nested maps" do
      input = %{user: %{name: "John", age: 30}}
      expected = %{"user" => %{"name" => "John", "age" => 30}}

      assert Helpers.stringify_keys(input) == expected
    end

    test "handles lists of maps" do
      input = [%{name: "John"}, %{age: 30}]
      expected = [%{"name" => "John"}, %{"age" => 30}]

      assert Helpers.stringify_keys(input) == expected
    end

    test "handles nil input" do
      assert Helpers.stringify_keys(nil) == nil
    end

    test "handles non-map values" do
      assert Helpers.stringify_keys("string") == "string"
      assert Helpers.stringify_keys(123) == 123
    end

    test "preserves string keys" do
      input = %{"name" => "John"}
      expected = %{"name" => "John"}

      assert Helpers.stringify_keys(input) == expected
    end
  end

  describe "deep_merge/2" do
    test "merges simple maps" do
      left = %{a: 1, b: 2}
      right = %{b: 3, c: 4}
      expected = %{a: 1, b: 3, c: 4}

      assert Helpers.deep_merge(left, right) == expected
    end

    test "merges nested maps recursively" do
      left = %{user: %{name: "John", age: 30}}
      right = %{user: %{age: 31, city: "NYC"}}
      expected = %{user: %{name: "John", age: 31, city: "NYC"}}

      assert Helpers.deep_merge(left, right) == expected
    end

    test "handles empty maps" do
      left = %{}
      right = %{a: 1}
      expected = %{a: 1}

      assert Helpers.deep_merge(left, right) == expected
    end

    test "prefers right value when both are non-maps" do
      left = %{a: 1}
      right = %{a: 2}
      expected = %{a: 2}

      assert Helpers.deep_merge(left, right) == expected
    end

    test "handles complex nested structures" do
      left = %{
        users: [%{name: "John"}, %{name: "Jane"}],
        config: %{debug: true}
      }

      right = %{
        users: [%{age: 30}, %{age: 25}],
        config: %{debug: false, timeout: 5000}
      }

      expected = %{
        users: [%{age: 30}, %{age: 25}],
        config: %{debug: false, timeout: 5000}
      }

      assert Helpers.deep_merge(left, right) == expected
    end
  end
end
