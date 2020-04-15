defmodule TdAuditWeb.SubscriptionControllerTest do
  @moduledoc """
  New test for the subscription controller
  """
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
      assert %{"data" => [data]} =
               conn
               |> get(Routes.subscription_path(conn, :index))
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      assert data["id"] == subscription.id
      assert data["event"] == subscription.event
      assert data["resource_type"] == subscription.resource_type
      assert data["resource_id"] == subscription.resource_id
      assert data["user_email"] == subscription.user_email
      assert data["periodicity"] == subscription.periodicity
    end

    @tag authenticated_user: @admin_user_name
    test "lists all subscriptions filtered", %{conn: conn, swagger_schema: schema} do
      %{id: id, event: event, resource_id: resource_id, resource_type: resource_type} =
        100_000..100_005
        |> Enum.map(&insert(:subscription, resource_id: &1))
        |> Enum.random()

      assert %{"data" => [data]} =
               conn
               |> get(
                 Routes.subscription_path(conn, :index,
                   resource_id: resource_id,
                   resource_type: resource_type
                 )
               )
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      assert %{
               "event" => ^event,
               "id" => ^id,
               "resource_type" => ^resource_type,
               "resource_id" => ^resource_id
             } = data
    end
  end

  describe "create subscription" do
    @tag authenticated_user: @admin_user_name
    test "renders a subscription when data is valid", %{conn: conn, swagger_schema: schema} do
      params = %{
        "event" => "foo",
        "resource_type" => "bar",
        "resource_id" => 123,
        "user_email" => "user@example.com",
        "periodicity" => "daily",
        "last_consumed_event" => "2020-02-02T01:23:45.000000Z"
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.subscription_path(conn, :create), subscription: params)
               |> validate_resp_schema(schema, "SubscriptionResponse")
               |> json_response(:created)

      assert %{"id" => id} = data

      assert %{"data" => data} =
               conn
               |> get(Routes.subscription_path(conn, :show, id))
               |> validate_resp_schema(schema, "SubscriptionResponse")
               |> json_response(:ok)

      assert Map.delete(data, "id") == params
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn} do
      missing_email = %{
        event: "some_event",
        resource_type: "some resource type",
        resource_id: 123,
        periodicity: "daily"
      }

      assert %{"errors" => errors} =
               conn
               |> post(Routes.subscription_path(conn, :create), subscription: missing_email)
               |> json_response(:unprocessable_entity)

      assert %{"user_email" => ["can't be blank"]} = errors
    end
  end

  describe "update subscription" do
    @tag authenticated_user: @admin_user_name
    test "renders subscription when data is valid", %{
      conn: conn,
      subscription: %{id: id} = subscription,
      swagger_schema: schema
    } do
      params = %{
        "event" => "foo",
        "resource_type" => "bar",
        "resource_id" => 123,
        "user_email" => "user@example.com",
        "periodicity" => "daily"
      }

      assert conn
             |> put(Routes.subscription_path(conn, :update, subscription), subscription: params)
             |> validate_resp_schema(schema, "SubscriptionResponse")
             |> json_response(:ok)

      assert %{"data" => data} =
               conn
               |> get(Routes.subscription_path(conn, :show, id))
               |> validate_resp_schema(schema, "SubscriptionResponse")
               |> json_response(:ok)

      assert Map.take(data, Map.keys(params)) == params
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn, subscription: subscription} do
      params = %{user_email: nil, periodicity: "monthly"}

      assert %{"errors" => errors} =
               conn
               |> put(Routes.subscription_path(conn, :update, subscription), subscription: params)
               |> json_response(:unprocessable_entity)

      assert %{"user_email" => ["can't be blank"]} = errors
    end
  end

  describe "delete subscription" do
    @tag authenticated_user: @admin_user_name
    test "deletes chosen subscription", %{conn: conn, subscription: subscription} do
      assert conn
             |> delete(Routes.subscription_path(conn, :delete, subscription))
             |> response(:no_content)

      assert_error_sent(:not_found, fn ->
        get(conn, Routes.subscription_path(conn, :show, subscription))
      end)
    end
  end
end
