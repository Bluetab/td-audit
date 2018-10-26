defmodule TdAudit.Notifications.Messages do
  @moduledoc false
  def content_on_comment_creation(
    %{
      "who" => who,
      "entity_name" => entity_name,
      "content" => content
    }) do
    %{
      subject: "<h1>#{who} has written a new comment on business concept #{entity_name}.</h1>",
      body: "<i>#{content}</i>"
    }
  end
end
