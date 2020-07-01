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

      params =
        string_params_for(:subscription, subscriber_id: subscriber_id)

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
