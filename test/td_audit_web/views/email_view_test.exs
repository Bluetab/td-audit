defmodule TdAuditWeb.EmailViewTest do
  use TdAuditWeb.ConnCase, async: true
  alias Phoenix.HTML.Safe
  alias TdAuditWeb.EmailView

  test "renders rule_result_created.html using configured timezone" do
    payload =
      string_params_for(
        :payload,
        date: "2022-02-12T11:46:39Z",
        result_type: "percentage",
        goal: 10.0,
        minimum: 0.0,
        errors: 0,
        records: 1,
        result: 100.00
      )

    assert EmailView.render(
             "rule_result_created.html",
             %{event: build(:event, event: "rule_result_created", payload: payload)}
           )
           |> Safe.to_iodata()
           |> IO.iodata_to_binary() =~ TdAudit.Helpers.shift_zone(payload["date"])
  end

  test "data structure event: renders data structure link: /structures/<data_structure_id>" do
    data_structure_id = 1234
    data_structure_event = "structure_tag_linked"

    payload =
      string_params_for(
        :payload,
        event: data_structure_event,
        data_structure_id: data_structure_id
      )

    assert EmailView.render(
             "#{data_structure_event}.html",
             %{
               event:
                 build(:event,
                   resource_type: "data_structure",
                   resource_id: data_structure_id,
                   event: data_structure_event,
                   payload: payload
                 )
             }
           )
           |> Safe.to_iodata()
           # Escaped quote is the anchor href ending quote
           |> IO.iodata_to_binary() =~ "/structures/#{data_structure_id}\""
  end

  test "note event: renders note link: /structures/<data_structure_id>/notes" do
    data_structure_id = 1234
    note_event = "structure_note_pending_approval"

    payload =
      string_params_for(
        :payload,
        event: note_event,
        data_structure_id: data_structure_id
      )

    assert EmailView.render(
             "#{note_event}.html",
             %{
               event:
                 build(:event,
                   resource_type: "data_structure_note",
                   event: note_event,
                   payload: payload
                 )
             }
           )
           |> Safe.to_iodata()
           |> IO.iodata_to_binary() =~ "/structures/#{data_structure_id}/notes"
  end
end
