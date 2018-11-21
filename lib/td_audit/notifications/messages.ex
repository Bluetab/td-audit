defmodule TdAudit.Notifications.Messages do
  @moduledoc false
  def content_on_comment_creation(
    %{
      "who" => who,
      "entity_name" => entity_name,
      "content" => content
    }) do
    %{
      subject: "Nuevo comentario en concepto de negocio #{entity_name}.",
      body: "<p><b>#{who}</b> ha creado un nuevo comentario en el concepto <b>#{entity_name}</b>:</p></br><p><i>\"#{content}\"</i></p>"
    }
  end
end
