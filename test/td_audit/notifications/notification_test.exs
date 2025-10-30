defmodule TdAudit.Notifications.NotificationTest do
  use TdAudit.DataCase

  alias TdAudit.Notifications.Notification

  describe "changeset/1" do
    test "creates changeset with valid params" do
      params = %{subscription_id: 1, recipient_ids: [1, 2, 3]}

      changeset = Notification.changeset(params)

      assert changeset.valid?
      assert changeset.changes.subscription_id == 1
      assert changeset.changes.recipient_ids == [1, 2, 3]
    end

    test "creates changeset with minimal params" do
      params = %{recipient_ids: [1]}

      changeset = Notification.changeset(params)

      assert changeset.valid?
      assert changeset.changes.recipient_ids == [1]
    end

    test "accepts params without recipient_ids" do
      params = %{subscription_id: 1}

      changeset = Notification.changeset(params)

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :recipient_ids)
    end

    test "accepts empty recipient_ids array" do
      params = %{recipient_ids: []}

      changeset = Notification.changeset(params)

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :recipient_ids)
    end

    test "accepts empty subscription_id" do
      params = %{recipient_ids: [1, 2]}

      changeset = Notification.changeset(params)

      assert changeset.valid?
      assert changeset.changes.recipient_ids == [1, 2]
      refute Map.has_key?(changeset.changes, :subscription_id)
    end
  end

  describe "changeset/2" do
    test "updates existing notification" do
      notification = %Notification{subscription_id: 1, recipient_ids: [1, 2]}
      params = %{recipient_ids: [3, 4, 5]}

      changeset = Notification.changeset(notification, params)

      assert changeset.valid?
      assert changeset.changes.recipient_ids == [3, 4, 5]
      refute Map.has_key?(changeset.changes, :subscription_id)
    end

    test "accepts empty params on update" do
      notification = %Notification{subscription_id: 1, recipient_ids: [1, 2]}
      params = %{}

      changeset = Notification.changeset(notification, params)

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :recipient_ids)
      refute Map.has_key?(changeset.changes, :subscription_id)
    end

    test "allows updating subscription_id" do
      notification = %Notification{subscription_id: 1, recipient_ids: [1, 2]}
      params = %{subscription_id: 2}

      changeset = Notification.changeset(notification, params)

      assert changeset.valid?
      assert changeset.changes.subscription_id == 2
      refute Map.has_key?(changeset.changes, :recipient_ids)
    end
  end
end
