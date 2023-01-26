defmodule TdAuditWeb.NotificationControllerTest do
  use TdAuditWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAudit.Notifications

  setup %{conn: conn} do
    [conn: put_req_header(conn, "accept", "application/json")]
  end

  describe "POST /notifications/user/me/search" do
    @tag :admin_authenticated
    test "lists all user subscriptions", %{
      conn: conn,
      claims: %{user_id: user_id},
      swagger_schema: schema
    } do
      %{id: notification_id, inserted_at: notification_date, events: [%{id: event_id}]} =
        insert(:notification, recipient_ids: [user_id])

      _other_not_in_results = insert(:notification)

      assert %{"data" => data} =
               conn
               |> post(Routes.notification_path(conn, :index_by_user))
               |> validate_resp_schema(schema, "NotificationsResponse")
               |> json_response(:ok)

      datetime_string = DateTime.to_iso8601(notification_date)

      assert [
               %{
                 "id" => ^notification_id,
                 "inserted_at" => ^datetime_string,
                 "events" => [%{"id" => ^event_id}]
               }
             ] = data
    end

    @tag :admin_authenticated
    test "group structure_note field events with same parent", %{
      conn: conn,
      claims: %{user_id: user_id},
      swagger_schema: schema
    } do
      %{id: domain_id} = CacheHelpers.put_domain()
      field_parent_id = System.unique_integer([:positive])
      structure_id_1 = System.unique_integer([:positive])
      structure_id_2 = System.unique_integer([:positive])

      payload_1 =
        string_params_for(
          :payload,
          data_structure_id: structure_id_1,
          field_parent_id: field_parent_id,
          domain_ids: [domain_id],
          resource: %{
            name: "child1",
            path: ["grampa", "parent"]
          }
        )

      payload_2 =
        string_params_for(
          :payload,
          data_structure_id: structure_id_2,
          field_parent_id: field_parent_id,
          domain_ids: [domain_id],
          resource: %{
            name: "child2",
            path: ["grampa", "parent"]
          }
        )

      events = [
        build(:event,
          event: "structure_note_updated",
          payload: payload_1,
          resource_type: "data_structure_note"
        ),
        build(:event,
          event: "structure_note_updated",
          payload: payload_2,
          resource_type: "data_structure_note"
        )
      ]

      %{id: notification_id, inserted_at: notification_date} =
        insert(:notification, recipient_ids: [user_id], events: events)

      _other_not_in_results = insert(:notification)

      assert %{"data" => data} =
               conn
               |> post(Routes.notification_path(conn, :index_by_user))
               |> validate_resp_schema(schema, "NotificationsResponse")
               |> json_response(:ok)

      datetime_string = DateTime.to_iso8601(notification_date)
      expected_path = "/structures/#{field_parent_id}/notes"

      assert [
               %{
                 "id" => ^notification_id,
                 "inserted_at" => ^datetime_string,
                 "events" => [
                   %{
                     "name" => "grampa > parent",
                     "path" => ^expected_path
                   }
                 ]
               }
             ] = data
    end

    @tag :admin_authenticated
    test "list notifications with read mark", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      insert(:notification, recipient_ids: [user_id])

      _other_not_in_results = insert(:notification)

      assert %{"data" => [%{"read_mark" => false}]} =
               conn
               |> post(Routes.notification_path(conn, :index_by_user))
               |> json_response(:ok)
    end
  end

  describe "POST /notifications/:id/read" do
    @tag :admin_authenticated
    test "read a notification", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      %{id: notification_id} = insert(:notification, recipient_ids: [user_id])

      _other_not_in_results = insert(:notification)

      assert [%{read_mark: false}] = Notifications.list_notifications(user_id)

      assert conn
             |> post(Routes.notification_path(conn, :read, notification_id))
             |> response(:ok)

      assert [%{read_mark: true}] = Notifications.list_notifications(user_id)
    end
  end

  describe "POST /notifications" do
    @tag :admin_authenticated
    test "Create share notification with admin user", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      params = %{
        "headers" => %{
          "subject" => "foo subject"
        },
        "message" => "bar message",
        "recipients" => [
          %{
            "id" => user_id,
            "role" => "admin"
          }
        ],
        "resource" => %{
          "description" => nil,
          "name" => "td_dd"
        },
        "uri" => "/foo/bar"
      }

      assert conn
             |> post(Routes.notification_path(conn, :create), notification: params)
             |> response(:accepted)
    end

    @tag :authenticated_user
    test "Create share notification with no admin user", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      params = %{
        "headers" => %{
          "subject" => "foo subject"
        },
        "message" => "bar message",
        "recipients" => [
          %{
            "id" => user_id,
            "role" => "admin"
          }
        ],
        "resource" => %{
          "description" => nil,
          "name" => "td_dd"
        },
        "uri" => "/foo/bar"
      }

      assert conn
             |> post(Routes.notification_path(conn, :create), notification: params)
             |> response(:accepted)
    end

    @tag :admin_authenticated
    test "Create external notification with admin user", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      params = %{
        "headers" => %{
          "subject" => "foo subject"
        },
        "message" => "bar message",
        "recipients" => [
          %{
            "id" => user_id,
            "role" => "admin"
          }
        ],
        "uri" => "http://foo.bar"
      }

      assert conn
             |> post(Routes.notification_path(conn, :create), notification: params)
             |> response(:accepted)
    end

    @tag :authenticated_user
    test "Create external notification with no admin user", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      params = %{
        "headers" => %{
          "subject" => "foo subject"
        },
        "message" => "bar message",
        "recipients" => [
          %{
            "id" => user_id,
            "role" => "admin"
          }
        ],
        "uri" => "http://foo.bar"
      }

      assert conn
             |> post(Routes.notification_path(conn, :create), notification: params)
             |> response(:forbidden)
    end
  end
end
