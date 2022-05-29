defmodule TdAuditWeb.EmailViewTest do
  use TdAuditWeb.ConnCase, async: true
  alias Phoenix.HTML.Safe
  alias TdAuditWeb.EmailView

  test "renders rule_result_created.html using configured timezone" do
    payload =
      string_params_for(
        :payload,
        event: "rule_result_created",
        date: "2022-02-12T11:46:39Z",
      )

    assert EmailView.render(
             "rule_result_created.html",
             %{event: build(:event, event: "rule_result_created", payload: payload)}
           )
           |> Safe.to_iodata()
           |> IO.iodata_to_binary() =~ TdAudit.Helpers.shift_zone(payload["date"])
  end

  test "implementation with parent rule, rule_result_created event: renders implementation result anchor: result link href and 'rule_name : implementation_key' content" do
    implementation_id = 12345
    rule_name = "rule_name"
    implementation_key = "implementation_key_as_resource_name"
    payload = # payload with rule "name" param
      string_params_for(
        :payload,
        date: "2022-02-12T11:46:39Z",
        result_type: "percentage",
        goal: 10.0,
        minimum: 0.0,
        errors: 0,
        records: 1,
        result: 100.00,
        name: rule_name,
        implementation_key: implementation_key,
        implementation_id: implementation_id,
      )

    email = EmailView.render(
             "rule_result_created.html",
             %{event: build(:event, event: "rule_result_created", payload: payload)}
           )
           |> Safe.to_iodata()
           |> IO.iodata_to_binary()

    assert email =~ ~r|<a href=".*/implementations/#{implementation_id}/results".*>\n*\s*#{rule_name} : #{implementation_key}\n*\s*</a>|
  end


  test "implementation wihout parent rule, rule_result_created event: renders implementation result anchor: result link href and 'implementation_key' content" do
    implementation_id = 12345
    implementation_key = "implementation_key_as_resource_name"
    payload = # payload without rule "name" param
      string_params_for(
        :payload,
        date: "2022-02-12T11:46:39Z",
        result_type: "percentage",
        goal: 10.0,
        minimum: 0.0,
        errors: 0,
        records: 1,
        result: 100.00,
        implementation_key: implementation_key,
        implementation_id: implementation_id,
      )

    email = EmailView.render(
             "rule_result_created.html",
             %{event: build(:event, event: "rule_result_created", payload: payload)}
           )
           |> Safe.to_iodata()
           |> IO.iodata_to_binary()

    assert email =~ ~r|<a href=".*/implementations/#{implementation_id}/results".*>\n*\s*#{implementation_key}\n*\s*</a>|
  end

  test "implementation created event: renders implementation link: /implementations/<implementation_id>" do
    implementation_id = 12345
    payload =
      string_params_for(
        :payload,
        implementation_id: implementation_id,
      )

    assert EmailView.render(
             "implementation_created.html",
             %{event: build(:event, event: "implementation_created", resource_id: implementation_id, payload: payload)}
           )
           |> Safe.to_iodata()
           |> IO.iodata_to_binary() =~ ~r|<a href=".*/implementations/#{implementation_id}"|
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
           |> IO.iodata_to_binary() =~ ~r|<a href=".*/structures/#{data_structure_id}"|
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
           |> IO.iodata_to_binary() =~ ~r|<a href=".*/structures/#{data_structure_id}/notes"|
  end
end
