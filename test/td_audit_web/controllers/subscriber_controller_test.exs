defmodule TdAuditWeb.SubscriberControllerTest do
  @moduledoc """
  New test for the subscriber controller
  """
  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  setup %{conn: conn} do
    subscriber = insert(:subscriber)
    [conn: put_req_header(conn, "accept", "application/json"), subscriber: subscriber]
  end

  describe "GET /api/subscribers" do
    @tag :admin_authenticated
    test "lists all subscribers", %{conn: conn, swagger_schema: schema, subscriber: subscriber} do
      %{id: id, type: type, identifier: identifier} = subscriber

      assert %{"data" => [data]} =
               conn
               |> get(Routes.subscriber_path(conn, :index))
               |> validate_resp_schema(schema, "SubscribersResponse")
               |> json_response(:ok)

      assert %{"id" => ^id, "type" => ^type, "identifier" => ^identifier} = data
    end
  end

  describe "GET /api/subscribers/:id" do
    @tag :admin_authenticated
    test "renders a subscriber", %{conn: conn, swagger_schema: schema, subscriber: subscriber} do
      %{id: id, type: type, identifier: identifier} = subscriber

      assert %{"data" => data} =
               conn
               |> get(Routes.subscriber_path(conn, :show, id))
               |> validate_resp_schema(schema, "SubscriberResponse")
               |> json_response(:ok)

      assert %{"id" => ^id, "type" => ^type, "identifier" => ^identifier} = data
    end
  end

  describe "POST /api/subscribers" do
    @tag :admin_authenticated
    test "renders a subscriber when data is valid", %{conn: conn, swagger_schema: schema} do
      params = %{
        "type" => "role",
        "identifier" => "data_owner"
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.subscriber_path(conn, :create), subscriber: params)
               |> validate_resp_schema(schema, "SubscriberResponse")
               |> json_response(:created)

      assert %{"id" => _id} = data
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.subscriber_path(conn, :create), subscriber: %{})
               |> json_response(:unprocessable_entity)

      assert %{"type" => ["can't be blank"]} = errors
    end
  end

  describe "DELETE /api/subscribers/:id" do
    @tag :admin_authenticated
    test "deletes the subscriber", %{conn: conn, subscriber: subscriber} do
      assert conn
             |> delete(Routes.subscriber_path(conn, :delete, subscriber))
             |> response(:no_content)

      assert_error_sent(:not_found, fn ->
        get(conn, Routes.subscriber_path(conn, :show, subscriber))
      end)
    end
  end
end
