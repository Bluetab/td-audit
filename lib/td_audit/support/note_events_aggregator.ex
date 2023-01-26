defmodule TdAudit.Support.NoteEventsAggregator do
  @moduledoc """
  Support function to aggregate StructureNote events with same parent
  """

  def maybe_group_events(events) do
    mapped_events = Enum.map(events, &map_note_events_group/1)

    group_events = Enum.reject(mapped_events, fn %{group_id: {_, id}} -> is_nil(id) end)

    non_group_events =
      mapped_events
      |> Enum.filter(fn %{group_id: {_, id}} -> is_nil(id) end)
      |> Enum.map(&Map.drop(&1, [:group_id]))

    group_events =
      group_events
      |> Enum.group_by(& &1.group_id)
      |> Enum.map(&parse_note_events_groups/1)

    group_events ++ non_group_events
  end

  defp map_note_events_group(%{event: event_type} = event) do
    group_id =
      case event do
        %{payload: %{"field_parent_id" => field_parent_id}} when not is_nil(field_parent_id) ->
          field_parent_id

        %{payload: %{"data_structure_id" => data_structure_id}} ->
          data_structure_id

        _ ->
          nil
      end

    Map.put(event, :group_id, {event_type, group_id})
  end

  defp parse_note_events_groups({_, [event]}), do: event

  defp parse_note_events_groups({{_, field_parent_id}, events}) do
    payload =
      events
      |> Enum.find(&(Map.get(&1.payload, "data_structure_id") == field_parent_id))
      |> handle_note_parent(events)

    updated_children =
      events
      |> Enum.reject(fn %{payload: %{"data_structure_id" => id}} -> id == field_parent_id end)
      |> Enum.map(fn
        %{payload: %{"resource" => %{"name" => name}}} -> name
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    events
    |> hd()
    |> Map.put(:payload, payload)
    |> Map.put(:updated_children, updated_children)
  end

  defp handle_note_parent(%{payload: payload}, _), do: payload

  defp handle_note_parent(_, [%{payload: child_payload} | _] = events) do
    domain_ids =
      events
      |> Enum.flat_map(fn event ->
        event
        |> Map.get(:payload)
        |> Map.get("domain_ids", [])
      end)
      |> Enum.uniq()

    data_structure_id = Map.get(child_payload, "field_parent_id")
    path = note_parent_path(child_payload)
    name = note_parent_name(child_payload)

    %{
      "domain_ids" => domain_ids,
      "data_structure_id" => data_structure_id,
      "resource" => %{
        "path" => path,
        "name" => name
      }
    }
  end

  defp note_parent_path(%{"resource" => %{"path" => [_ | _] = path}}), do: Enum.drop(path, -1)
  defp note_parent_path(_), do: []

  defp note_parent_name(%{"resource" => %{"path" => [_ | _] = path}}),
    do: path |> Enum.take(-1) |> hd()

  defp note_parent_name(_), do: nil
end
