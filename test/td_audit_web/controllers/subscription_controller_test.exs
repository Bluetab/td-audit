defmodule TdAuditWeb.SubscriptionControllerTest do
  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  setup %{conn: conn} do
    [conn: put_req_header(conn, "accept", "application/json")]
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all subscriptions", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{id: subscription_id} = insert(:subscription)

      assert %{"data" => [data]} =
               conn
               |> get(Routes.subscription_path(conn, :index))
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      assert %{"id" => ^subscription_id} = data
    end

    @tag :authenticated_user
    test "index requires admin users", %{conn: conn} do
      conn = get(conn, Routes.subscription_path(conn, :index))
      assert json_response(conn, :forbidden)
    end

    @tag :admin_authenticated
    test "lists all subscriptions filtered", %{conn: conn, swagger_schema: schema} do
      %{id: id, subscriber_id: subscriber_id} = insert(:subscription)
      _other = insert(:subscription)

      assert %{"data" => [data]} =
               conn
               |> get(Routes.subscription_path(conn, :index, subscriber_id: subscriber_id))
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      assert %{"id" => ^id, "subscriber" => %{"id" => ^subscriber_id}} = data
    end
  end

  describe "index_by_user" do
    @tag :authenticated_user
    test "lists all user subscriptions", %{
      conn: conn,
      claims: %{user_id: user_id},
      swagger_schema: schema
    } do
      %{id: subscriber_id} = insert(:subscriber, identifier: "#{user_id}", type: "user")

      scope =
        build(:scope,
          events: ["rule_result_created"],
          status: ["error"],
          resource_type: "rule",
          resource_id: 28_280
        )

      s1 = insert(:subscription, subscriber_id: subscriber_id, scope: scope)
      _s2 = insert(:subscription, subscriber_id: subscriber_id)

      filters = %{
        filters: %{
          scope: %{
            events: ["rule_result_created"]
          }
        }
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.subscription_path(conn, :index_by_user), filters)
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      data_ids = Enum.map(data, &Map.get(&1, "id"))
      assert data_ids == [s1.id]
    end
  end

  describe "show subscription" do
    @tag :authenticated_user
    test "show requires admin users", %{conn: conn} do
      subscription = insert(:subscription)
      conn = get(conn, Routes.subscription_path(conn, :show, subscription))
      assert json_response(conn, :forbidden)
    end

    @tag :admin_authenticated
    test "renders a subscription", %{conn: conn, swagger_schema: schema} do
      %{id: id, periodicity: periodicity, subscriber_id: subscriber_id} = insert(:subscription)

      assert %{"data" => data} =
               conn
               |> get(Routes.subscription_path(conn, :show, id))
               |> validate_resp_schema(schema, "SubscriptionResponse")
               |> json_response(:ok)

      assert %{
               "id" => ^id,
               "last_event_id" => _last_event_id,
               "periodicity" => ^periodicity,
               "subscriber" => %{"id" => ^subscriber_id},
               "scope" => _scope
             } = data
    end

    @tag :admin_authenticated
    test "renders a subscription with concept resource", %{conn: conn, swagger_schema: schema} do
      %{id: id, periodicity: periodicity, subscriber_id: subscriber_id} =
        insert(:concept_subscription, resource_id: 1)

      assert %{"data" => data} =
        conn
        |> get(Routes.subscription_path(conn, :show, id))
        |> validate_resp_schema(schema, "SubscriptionResponse")
        |> json_response(:ok)

      assert %{
               "id" => ^id,
               "subscriber" => %{"id" => ^subscriber_id},
               "periodicity" => ^periodicity,
               "resource" => %{
                 "id" => 1,
                 "name" => "concept",
                 "business_concept_version_id" => "4"
               }
             } = data
    end

    @tag :admin_authenticated
    test "renders a subscription with domains resource", %{conn: conn, swagger_schema: schema} do
      %{id: id, periodicity: periodicity, subscriber_id: subscriber_id} =
        insert(:domains_subscription, resource_id: 2)

        assert %{"data" => data} =
          conn
          |> get(Routes.subscription_path(conn, :show, id))
          |> validate_resp_schema(schema, "SubscriptionResponse")
          |> json_response(:ok)

      assert %{
               "id" => ^id,
               "subscriber" => %{"id" => ^subscriber_id},
               "periodicity" => ^periodicity,
               "resource" => %{
                 "id" => 2,
                 "name" => "domain"
               }
             } = data
    end

    @tag :admin_authenticated
    test "renders a subscription with rule resource", %{conn: conn, swagger_schema: schema} do
      %{id: id, periodicity: periodicity, subscriber_id: subscriber_id} =
        insert(:rule_subscription, resource_id: 3)

        assert %{"data" => data} =
          conn
          |> get(Routes.subscription_path(conn, :show, id))
          |> validate_resp_schema(schema, "SubscriptionResponse")
          |> json_response(:ok)

      assert %{
               "id" => ^id,
               "subscriber" => %{"id" => ^subscriber_id},
               "periodicity" => ^periodicity,
               "resource" => %{
                 "id" => 3,
                 "name" => "rule"
               }
             } = data
    end
  end

  describe "create subscription" do
    @tag :admin_authenticated
    test "renders a subscription when data is valid", %{conn: conn, swagger_schema: schema} do
      %{id: subscriber_id} = insert(:subscriber)

      params = string_params_for(:subscription, subscriber_id: subscriber_id)

      assert %{"data" => data} =
               conn
               |> post(Routes.subscription_path(conn, :create), subscription: params)
               |> validate_resp_schema(schema, "SubscriptionResponse")
               |> json_response(:created)

      assert %{
               "id" => _id,
               "last_event_id" => _last_event_id,
               "periodicity" => _periodicity,
               "subscriber" => %{"id" => ^subscriber_id},
               "scope" => _scope
             } = data
    end

    @tag :authenticated_user
    test "creating a subscription without subscriber identifier will use current user", %{conn: conn, claims: claims, swagger_schema: schema} do
      params =
        :subscription
        |> string_params_for()
        |> Map.put("subscriber", %{"type" => "user"})

      assert %{"data" => data} =
        conn
        |> post(Routes.subscription_path(conn, :create), subscription: params)
        |> validate_resp_schema(schema, "SubscriptionResponse")
        |> json_response(:created)

      subscriber_id = "#{claims.user_id}"
      assert %{"subscriber" => %{"identifier" => ^subscriber_id}} = data
    end

    @tag :admin_authenticated
    test "creating a subscription without subscriber will return unprocessable entity", %{conn: conn} do
      params = string_params_for(:subscription)

      assert %{"errors" => errors} =
        conn
        |> post(Routes.subscription_path(conn, :create), subscription: params)
        |> json_response(:unprocessable_entity)

      assert %{"subscriber" => ["can't be blank"]} = errors
    end

    @tag :authenticated_user
    test "normal user cannot create a subscription with subscriber type different from user", %{conn: conn} do
      params =
        :subscription
        |> string_params_for()
        |> Map.put("subscriber", %{"type" => "role", "identifier" => "Data Owner"})

      assert conn
        |> post(Routes.subscription_path(conn, :create), subscription: params)
        |> json_response(:forbidden)
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.subscription_path(conn, :create), subscription: %{})
               |> json_response(:unprocessable_entity)

      assert %{
               "periodicity" => ["can't be blank"],
               "scope" => ["can't be blank"],
               "subscriber" => ["can't be blank"]
             } = errors
    end
  end

  describe "update subscription" do
    @tag :authenticated_user
    test "updates a subscription when data is valid", %{
      conn: conn,
      claims: %{user_id: user_id},
      swagger_schema: schema
    } do
      %{id: subscriber_id} = insert(:subscriber, identifier: "#{user_id}", type: "user")

      scope =
        build(:scope,
          events: ["rule_result_created"],
          resource_type: "rule",
          resource_id: 28_280
        )

      subscription = insert(:subscription, subscriber_id: subscriber_id, scope: scope)

      update_params = %{"periodicity" => "hourly", "scope" => %{"status" => ["fail", "warn"]}}

      assert %{"data" => data} =
               conn
               |> put(Routes.subscription_path(conn, :update, subscription),
                 subscription: update_params
               )
               |> validate_resp_schema(schema, "SubscriptionResponse")
               |> json_response(:ok)

      assert %{
               "id" => _id,
               "last_event_id" => _last_event_id,
               "periodicity" => "hourly",
               "subscriber" => %{"id" => ^subscriber_id},
               "scope" => scope
             } = data

      assert Map.get(scope, "status") == ["fail", "warn"]
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.subscription_path(conn, :create), subscription: %{})
               |> json_response(:unprocessable_entity)

      assert %{
               "periodicity" => ["can't be blank"],
               "scope" => ["can't be blank"],
               "subscriber" => ["can't be blank"]
             } = errors
    end
  end

  describe "delete subscription" do
    @tag :authenticated_user
    test "deletes chosen subscription", %{conn: conn, claims: %{user_id: user_id}} do
      %{id: subscriber_id} = insert(:subscriber, identifier: "#{user_id}", type: "user")
      subscription = insert(:subscription, subscriber_id: subscriber_id)

      assert conn
             |> delete(Routes.subscription_path(conn, :delete, subscription))
             |> response(:no_content)

      assert_error_sent(:not_found, fn ->
        get(conn, Routes.subscription_path(conn, :show, subscription))
      end)
    end
  end
end
