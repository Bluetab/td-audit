defmodule TdAuditWeb.SubscriptionControllerTest do
  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  @admin_user_name "app-admin"

  setup %{conn: conn} do
    [conn: put_req_header(conn, "accept", "application/json")]
  end

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all subscriptions", %{
      conn: conn,
      swagger_schema: schema
    } do
      concept_id = 3
      %{id: concept_subscription_id, subscriber_id: concept_subscriber_id} =
        insert(:concept_subscription, resource_id: concept_id)

      domain_id = 6
      %{id: domains_subscription_id, subscriber_id: domains_subscriber_id} =
        insert(:domains_subscription, resource_id: domain_id)

      rule_id = 9
      %{id: rule_subscription_id, subscriber_id: rule_subscriber_id} =
        insert(:rule_subscription, resource_id: rule_id)

      assert %{"data" => data} =
               conn
               |> get(Routes.subscription_path(conn, :index))
               |> validate_resp_schema(schema, "SubscriptionsResponse")
               |> json_response(:ok)

      assert concept_subscription = Enum.find(data, & &1["id"] == concept_subscription_id)

      assert %{
        "subscriber" => %{"id" => ^concept_subscriber_id},
        "resource" => %{
          "id" => ^concept_id,
          "name" => "concept",
          "business_concept_version_id" => "4"
        }
      } = concept_subscription

      assert domain_subscription = Enum.find(data, & &1["id"] == domains_subscription_id)

      assert %{
        "subscriber" => %{"id" => ^domains_subscriber_id},
        "resource" => %{
          "id" => ^domain_id,
          "name" => "domain",
        }
      } = domain_subscription

      assert rule_subscription = Enum.find(data, & &1["id"] == rule_subscription_id)

      assert %{
        "subscriber" => %{"id" => ^rule_subscriber_id},
        "resource" => %{
          "id" => ^rule_id,
          "name" => "rule",
        }
      } = rule_subscription
    end

    @tag authenticated_user: @admin_user_name
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
    @tag authenticated_user: @admin_user_name
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
