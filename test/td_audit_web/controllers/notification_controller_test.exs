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
end
