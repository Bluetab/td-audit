defmodule TdAudit.NotificationsManager do
  @moduledoc """
  This module will dispatch the needed args depending on the received event to the proper
  notifications dispatcher
  """

  def send_notification_on_event(%{
        "event" => "create_comment",
        "service" => "td_bg",
        "payload" => _payload
      }) do
    # TODO
  end

  def send_notification_on_event(%{
    "event" => _,
    "service" => _,
    "payload" => _
  }) do
  # TODO
  end
end
