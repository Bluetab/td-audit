defmodule TdAuditWeb.SubscriptionControllerTest do
  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  @admin_user_name "app-admin"

  setup %{conn: conn} do
    subscription = insert(:subscription)
    [conn: put_req_header(conn, "accept", "application/json"), subscription: subscription]
  end

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all subscriptions", %{
      conn: conn,
      swagger_schema: schema,
      subscription: subscription
    } do
      %{id: id, subscriber_id: subscriber_id} = subscription

      assert %{"data" => [data]} =
               conn
               |> get(Routes.subscription_path(conn, :index))
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      assert %{"id" => ^id, "subscriber" => %{"id" => ^subscriber_id}} = data
    end

    @tag authenticated_user: @admin_user_name
    test "lists all subscriptions filtered", %{conn: conn, swagger_schema: schema} do
      %{id: id, subscriber_id: subscriber_id} =
        1..5
        |> Enum.map(fn _ -> insert(:subscription) end)
        |> Enum.random()

      assert %{"data" => [data]} =
               conn
               |> get(Routes.subscription_path(conn, :index, subscriber_id: subscriber_id))
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      assert %{"id" => ^id, "subscriber" => %{"id" => ^subscriber_id}} = data
    end
  end

  describe "index_by_user" do
    @tag authenticated_user: @admin_user_name
    test "lists all user subscriptions", %{
      conn: conn,
      session: %{user_id: user_id},
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
    @tag authenticated_user: @admin_user_name
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
  end

  describe "create subscription" do
    @tag authenticated_user: @admin_user_name
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

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.subscription_path(conn, :create), subscription: %{})
               |> json_response(:unprocessable_entity)

      assert %{
               "periodicity" => ["can't be blank"],
               "scope" => ["can't be blank"],
               "subscriber_id" => ["can't be blank"]
             } = errors
    end
  end

  describe "update subscription" do
    @tag authenticated_user: @admin_user_name
    test "updates a subscription when data is valid", %{
      conn: conn,
      session: %{user_id: user_id},
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

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.subscription_path(conn, :create), subscription: %{})
               |> json_response(:unprocessable_entity)

      assert %{
               "periodicity" => ["can't be blank"],
               "scope" => ["can't be blank"],
               "subscriber_id" => ["can't be blank"]
             } = errors
    end
  end

  describe "delete subscription" do
    @tag authenticated_user: @admin_user_name
    test "deletes chosen subscription", %{conn: conn, session: %{user_id: user_id}} do
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
