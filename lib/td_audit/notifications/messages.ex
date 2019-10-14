defmodule TdAudit.Notifications.Messages do
  @moduledoc false
  def content_on_comment_creation(%{
        "who" => who,
        "entity_name" => entity_name,
        "content" => content,
        "resource_link" => resource_link
      }) do
    %{
      subject: "Nuevo comentario en concepto de negocio #{entity_name}.",
      body:
        "<p><b>#{who}</b> ha creado un nuevo comentario en el concepto <a href=\"#{resource_link}\">#{
          entity_name
        }</a>:
      </p></br><p><i>\"#{content}\"</i></p>"
    }
  end

  def content_on_failed_rule_results(%{"content" => content}) do
    headers = "<tr>
      <th>Concepto de Negocio</th>
      <th>Regla</th>
      <th>Implemtación</th>
      <th>Umbral</th>
      <th>Resultado</th>
    </tr>"

    body = Enum.reduce(content, "", &table_line/2)

    %{
      subject: "Ejecuciones de reglas terminadas en error.",
      body: "<table>#{headers}#{body}</table>"
    }
  end

  defp table_line(
         %{
           business_concept_name: business_concept_name,
           implementation_key: implementation_key,
           result: result,
           rule_name: rule_name,
           concept_link: concept_link,
           rule_link: rule_link
         } = line,
         acc
       ) do
    minimum = Map.get(line, :minimum, "")
    acc <> "<tr>
      <td><a href=\"#{concept_link}\">#{business_concept_name}</a></td>
      <td><a href=\"#{rule_link}\">#{rule_name}</a></td>
      <td>#{implementation_key}</td>
      <td>#{minimum}</td>
      <td>#{result}</td>
    </tr>"
  end
end
