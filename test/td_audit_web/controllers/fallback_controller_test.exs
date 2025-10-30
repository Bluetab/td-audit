defmodule TdAuditWeb.FallbackControllerTest do
  use TdAuditWeb.ConnCase

  alias TdAuditWeb.FallbackController

  describe "call/2 with can: false" do
    test "renders 403 error", %{conn: conn} do
      conn = FallbackController.call(conn, {:can, false})

      assert conn.status == 403
      assert json_response(conn, 403)
    end
  end

  describe "call/2 with changeset error" do
    test "renders changeset errors", %{conn: conn} do
      changeset = %Ecto.Changeset{
        action: :insert,
        changes: %{},
        errors: [name: {"can't be blank", [validation: :required]}],
        data: %{},
        valid?: false
      }

      conn = FallbackController.call(conn, {:error, changeset})

      assert conn.status == 422
      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "sets unprocessable_entity status for changeset errors", %{conn: conn} do
      changeset = %Ecto.Changeset{
        action: :update,
        changes: %{},
        errors: [field: {"is invalid", []}],
        data: %{},
        valid?: false
      }

      conn = FallbackController.call(conn, {:error, changeset})

      assert conn.status == 422
    end
  end

  describe "call/2 with not_found error" do
    test "renders 404 error", %{conn: conn} do
      conn = FallbackController.call(conn, {:error, :not_found})

      assert conn.status == 404
      assert json_response(conn, 404)
    end
  end
end
