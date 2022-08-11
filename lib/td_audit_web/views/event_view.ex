defmodule TdAuditWeb.EventView do
  use TdAuditWeb, :view

  alias TdCache.ConceptCache

  def render("index.json", %{events: events}) do
    %{data: render_many(events, __MODULE__, "event.json")}
  end

  def render("show.json", %{event: event}) do
    %{data: render_one(event, __MODULE__, "event.json")}
  end

  def render("event.json", %{event: event}) do
    %{
      id: event.id,
      service: event.service,
      resource_id: event.resource_id,
      resource_type: event.resource_type,
      event: event.event,
      payload: event.payload,
      user_id: event.user_id,
      user_name: event.user_name,
      user: event.user,
      inserted_at: event.inserted_at,
      ts: event.ts
    }
  end

  def resource_name(%{event: "external_notification", payload: %{"message" => message}}),
    do: message

  def resource_name(%{event: "share_document", payload: %{"message" => message}}), do: message

  def resource_name(%{payload: %{"resource" => %{"name" => name, "path" => path = [_ | _]}}}) do
    full_path =
      path
      |> Enum.map(fn
        %{"name" => name} -> name
        name -> name
      end)
      |> Enum.concat([name])

    Enum.join(full_path, " > ")
  end

  def resource_name(%{payload: %{"resource" => %{"name" => name}}}), do: name

  def resource_name(%{
        payload: %{"rule_name" => name, "implementation_key" => implementation_key}
      }) do
    "#{name} / #{implementation_key}"
  end

  def resource_name(%{
        payload: %{"name" => name, "implementation_key" => implementation_key}
      }) do
    "#{name} : #{implementation_key}"
  end

  def resource_name(%{payload: %{"implementation_key" => implementation_key}}) do
    "#{implementation_key}"
  end

  def resource_name(%{payload: %{"resource_name" => name}}), do: name

  def resource_name(%{payload: %{"name" => name}}), do: name

  def resource_name(%{resource_id: resource_id, resource_type: "concept"}) do
    case ConceptCache.get(resource_id, :name) do
      {:ok, name} -> name
      _ -> nil
    end
  end

  def resource_name(_), do: nil

  def path(%{event: "external_notification", payload: %{"path" => path}}), do: path

  def path(%{event: "share_document", payload: %{"path" => path}}), do: path

  def path(%{
        resource_type: "comment",
        payload: %{"resource_type" => "ingest", "version_id" => id}
      }) do
    "/ingests/#{id}"
  end

  def path(%{
        resource_type: "comment",
        payload: %{
          "resource_type" => "business_concept",
          "resource_id" => resource_id,
          "version_id" => id
        }
      }) do
    "/concepts/#{resource_id}/versions/#{id}"
  end

  def path(%{resource_type: "ingest", payload: %{"id" => id}}) do
    "/ingests/#{id}"
  end

  def path(%{resource_type: "concept", event: event, resource_id: resource_id})
      when event in ["relation_created", "relation_deleted", "relation_deprecated"] do
    case ConceptCache.get(resource_id, :business_concept_version_id) do
      {:ok, version} -> "/concepts/#{resource_id}/versions/#{version}"
      _ -> nil
    end
  end

  def path(%{resource_type: "concept", resource_id: resource_id, payload: %{"id" => id}}) do
    "/concepts/#{resource_id}/versions/#{id}"
  end

  def path(%{resource_type: "rule_result", payload: %{"implementation_id" => implementation_id}}) do
    "/implementations/#{implementation_id}/results"
  end

  def path(%{resource_type: "implementation", resource_id: resource_id}) do
    "/implementations/#{resource_id}"
  end

  def path(%{resource_type: "rule", resource_id: resource_id}) do
    "/rules/#{resource_id}"
  end

  def path(%{resource_type: "data_structure", resource_id: id}) do
    "/structures/#{id}"
  end

  def path(%{resource_type: "data_structure_note", payload: %{"data_structure_id" => id}}) do
    "/structures/#{id}/notes"
  end

  def path(%{resource_type: "grant", payload: %{"data_structure_id" => id}}) do
    "/structures/#{id}"
  end

  def path(%{resource_type: "grant_requests", resource_id: id}) do
    "/grant_requests/#{id}"
  end

  def path(%{resource_type: "jobs", payload: %{"external_id" => id}}) do
    "/jobs/#{id}"
  end

  def path(%{resource_type: "sources", payload: %{"source_external_id" => id}}) do
    "/sources/#{id}"
  end

  def path(_), do: nil
end
