defmodule TdAuditWeb.SubscriptionControllerTest do
  @moduledoc """
  New test for the subscription controller
  """
  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuditWeb.Authentication, only: :functions

  alias TdAudit.Subscriptions
  alias TdAudit.Subscriptions.Subscription
  alias TdAuditWeb.ApiServices.MockTdAuthService

  @valid_attrs %{event: "some event", resource_id: 42, resource_type: "some resource_type", user_email: "mymail@foo.com", periodicity: "daily"}
  @invalid_attrs %{event: "some event", resource_type: "some resource_type", user_email: "mymail@foo.com", periodicity: "daily"}
  @update_attrs %{user_email: "mynewmail@foo.com", periodicity: "monthly"}
  @invalid_update_attrs %{user_email: nil, periodicity: "monthly"}

  @admin_user_name "app-admin"

  def subscription_fixture(attrs \\ %{}) do
    {:ok, subscription: subscription} = create_subscription(attrs)

    subscription
    |> Map.from_struct()
    |> Map.drop([:__meta__, :updated_at, :inserted_at])
    |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, Atom.to_string(key), val) end)
  end

  def create_subscription(attrs \\ %{}) do
    {:ok, subscription} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Subscriptions.create_subscription()

    {:ok, subscription: subscription}
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all subscriptions", %{conn: conn, swagger_schema: schema} do
      subscription = subscription_fixture()
      conn = get conn, subscription_path(conn, :index)
      validate_resp_schema(conn, schema, "SubscriptionsResponse")
      assert json_response(conn, 200)["data"] == [subscription]
    end

    @tag authenticated_user: @admin_user_name
    test "lists all subscriptions filtered", %{conn: conn, swagger_schema: schema} do
      resource_id_filter = 42
      resource_type_filter = "some resource_type"
      result_subscription = subscription_fixture()
      subscription_fixture(%{"resource_id": 43, "resource_type": "some new resource_type"})
      subscription_fixture(%{"resource_id": 44, "resource_type": "some new new resource_type"})
      conn = get conn, subscription_path(conn, :index, "resource_id": resource_id_filter, "resource_type": resource_type_filter)
      validate_resp_schema(conn, schema, "SubscriptionsResponse")
      assert json_response(conn, 200)["data"] == [result_subscription]
    end
  end

  describe "create subscription" do
    @tag authenticated_user: @admin_user_name
    test "renders a subscription when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, subscription_path(conn, :create), subscription: @valid_attrs
      validate_resp_schema(conn, schema, "SubscriptionResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, subscription_path(conn, :show, id)
      validate_resp_schema(conn, schema, "SubscriptionResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "event" => Map.get(@valid_attrs, :event),
        "resource_id" => Map.get(@valid_attrs, :resource_id),
        "resource_type" => Map.get(@valid_attrs, :resource_type),
        "user_email" => Map.get(@valid_attrs, :user_email),
        "periodicity" => Map.get(@valid_attrs, :periodicity)
      }
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, subscription_path(conn, :create), subscription: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update subscription" do
    setup [:create_subscription]
    @tag authenticated_user: @admin_user_name
    test "renders subscription when data is valid", %{conn: conn, subscription: %Subscription{id: id} = subscription, swagger_schema: schema} do
      conn = put conn, subscription_path(conn, :update, subscription), subscription: @update_attrs
      validate_resp_schema(conn, schema, "SubscriptionResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, subscription_path(conn, :show, id)
      validate_resp_schema(conn, schema, "SubscriptionResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "event" => Map.get(@valid_attrs, :event),
        "resource_id" => Map.get(@valid_attrs, :resource_id),
        "resource_type" => Map.get(@valid_attrs, :resource_type),
        "periodicity" =>  Map.get(@update_attrs, :periodicity),
        "user_email" => Map.get(@update_attrs, :user_email)}
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn, subscription: subscription} do
      conn = put conn, subscription_path(conn, :update, subscription), subscription: @invalid_update_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete subscription" do
    setup [:create_subscription]

    @tag authenticated_user: @admin_user_name
    test "deletes chosen subscription", %{conn: conn, subscription: subscription, swagger_schema: schema} do
      conn = delete conn, subscription_path(conn, :delete, subscription)
      assert response(conn, 204)

      conn = recycle_and_put_headers(conn)

      assert_error_sent 404, fn ->
        get conn, subscription_path(conn, :show, subscription)
        validate_resp_schema(conn, schema, "SubscriptionResponse")
      end
    end
  end
end
