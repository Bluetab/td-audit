defmodule TdAuditWeb.SubscriptionsControllerTest do
  @moduledoc """
  Subscriptions controller test
  """

  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  @admin_user_name "app-admin"
  @role "foo_role"

  setup %{conn: conn} do
    alias TdCache.{ConceptCache, UserCache}
    user = build(:user)
    UserCache.put(user)
    concepts = Enum.map(1..10, fn _ -> build(:concept, content: %{@role => user.full_name}) end)
    Enum.each(concepts, &ConceptCache.put/1)

    on_exit(fn ->
      Enum.each(concepts, &ConceptCache.delete(&1.id))
      UserCache.delete(user.id)
    end)

    [conn: put_req_header(conn, "accept", "application/json"), concepts: concepts, user: user]
  end

  describe "PATCH /api/subscriptions" do
    @tag authenticated_user: @admin_user_name
    test "creates multiple subscriptions", %{
      concepts: concepts,
      conn: conn,
      swagger_schema: schema,
      user: %{email: email}
    } do
      params = %{
        "role" => @role,
        "resource_type" => "business_concept",
        "event" => "comment_created",
        "periodicity" => "daily"
      }

      assert %{"data" => data} =
               conn
               |> patch(Routes.subscriptions_path(conn, :update), subscriptions: params)
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      assert Enum.count(data) == Enum.count(concepts)
      assert [subscription | _subscriptions] = data

      assert %{
               "event" => "comment_created",
               "periodicity" => "daily",
               "resource_type" => "business_concept",
               "user_email" => ^email
             } = subscription
    end
  end
end
