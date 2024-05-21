defmodule TdAuditWeb.EmailViewTest do
  use TdAuditWeb.ConnCase, async: true
  alias Phoenix.HTML.Safe
  alias TdAudit.EmailParser
  alias TdAuditWeb.EmailView

  test "renders rule_result_created.html using configured timezone" do
    implementation_id = 12_345

    payload =
      string_params_for(
        :payload,
        event: "rule_result_created",
        date: "2022-02-12T11:46:39Z",
        implementation_id: implementation_id
      )

    [{link, header, content}] =
      EmailView.render(
        "rule_result_created.html",
        %{event: build(:event, event: "rule_result_created", payload: payload)}
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    shifted_date = TdAudit.Helpers.shift_zone(payload["date"])

    assert link =~ ~r|.*/implementations/#{implementation_id}/results|
    assert header == "rule_name : ri123"

    assert [
             {"Date:", ^shifted_date},
             {"Target:", "100,00%"},
             {"Threshold:", "80,00%"},
             {"Result:", "70,00%"}
           ] = content
  end

  test "implementation with parent rule, rule_result_created event: renders implementation result anchor: result link href and 'rule_name : implementation_key' content" do
    implementation_id = 12_345
    rule_name = "rule_name"
    implementation_key = "implementation_key_as_resource_name"
    # payload with rule "name" param
    payload =
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
        implementation_id: implementation_id
      )

    [{link, header, content}] =
      EmailView.render(
        "rule_result_created.html",
        %{event: build(:event, event: "rule_result_created", payload: payload)}
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    shifted_date = TdAudit.Helpers.shift_zone(payload["date"])

    assert link =~ ~r|.*/implementations/#{implementation_id}/results|
    assert header == "#{rule_name} : #{implementation_key}"

    assert [
             {"Date:", ^shifted_date},
             {"Target:", "10,00%"},
             {"Threshold:", "0,00%"},
             {"Error Count:", "0"},
             {"Record Count:", "1"},
             {"Result:", "100,00%"}
           ] = content
  end

  test "implementation wihout parent rule, rule_result_created event: renders implementation result anchor: result link href and 'implementation_key' content" do
    implementation_id = 12_345
    implementation_key = "implementation_key_as_resource_name"
    # payload without rule "name" param
    payload =
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
        implementation_id: implementation_id
      )

    [{link, header, content}] =
      EmailView.render(
        "rule_result_created.html",
        %{event: build(:event, event: "rule_result_created", payload: payload)}
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    shifted_date = TdAudit.Helpers.shift_zone(payload["date"])

    assert link =~ ~r|.*/implementations/#{implementation_id}/results|
    assert header == implementation_key

    assert [
             {"Date:", ^shifted_date},
             {"Target:", "10,00%"},
             {"Threshold:", "0,00%"},
             {"Error Count:", "0"},
             {"Record Count:", "1"},
             {"Result:", "100,00%"}
           ] = content
  end

  test "implementation created event: renders implementation link: /implementations/<implementation_id>" do
    implementation_id = 12_345

    payload =
      string_params_for(
        :payload,
        implementation_id: implementation_id,
        implementation_key: "implementation_key"
      )

    [{link, header, content}] =
      EmailView.render(
        "implementation_created.html",
        %{
          event:
            build(:event,
              event: "implementation_created",
              resource_id: implementation_id,
              payload: payload
            )
        }
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    assert link =~ ~r|.*/implementations/#{implementation_id}|
    assert header == "implementation_key"

    assert [
             {"Evento:", "Implementation created"},
             {"Domain:", nil},
             {"User:", nil}
           ] = content
  end

  test "grant_request_group_creation event: renders grant requests links: /grantRequests/<id>" do
    grant_request_1_id = 361
    grant_request_2_id = 362
    group_id = 252

    payload =
      string_params_for(
        :payload,
        domain_ids: [2, 216],
        id: group_id,
        requests: [
          %{
            id: grant_request_1_id,
            data_structure: %{current_version: %{name: "structure_1"}}
          },
          %{
            id: grant_request_2_id,
            data_structure: %{current_version: %{name: "structure_2"}}
          }
        ]
      )

    [
      {"p", _, ["Grant request for the following structures:"]},
      {"p", _, ["User: "]},
      {"ul", _,
       [
         {"li", _, [{"a", [{"href", group_link}, _], [group_link_text]}]}
       ]}
    ] =
      EmailView.render(
        "grant_request_group_creation.html",
        %{
          event:
            build(:event,
              event: "grant_request_group_creation",
              resource_type: "grant_request_groups",
              resource_id: payload["id"],
              payload: payload
            )
        }
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()

    assert group_link =~ ~r|.*/grantRequestGroups/#{group_id}|
    assert String.trim(group_link_text) == group_link
  end

  test "grant_request_approvals event: renders grant requests links: /grantRequests/<id>" do
    grant_request_1_id = 361

    payload =
      string_params_for(
        :payload,
        comment: "Aprobación rol data owner",
        domain_ids: [2],
        grant_request: %{
          id: grant_request_1_id,
          data_structure: %{current_version: %{name: "structure_1"}}
        },
        status: "pending"
      )

    [{link, header, content}] =
      EmailView.render(
        "grant_request_approval_addition.html",
        %{
          event:
            build(:event,
              event: "grant_request_approval_addition",
              resource_type: "grant_request_approvals",
              payload: payload
            )
        }
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    assert link =~ ~r|.*/grantRequests/#{grant_request_1_id}|
    assert header == "structure_1"

    assert [
             "Grant request approval addition",
             {"Approver:", nil},
             {"Status:", "pending"},
             {"Approver comments:", "Aprobación rol data owner"}
           ] = content
  end

  test "grant_request_status event: renders grant requests links: /grantRequests/<id>" do
    grant_request_1_id = 361

    payload =
      string_params_for(
        :payload,
        domain_ids: [2],
        grant_request: %{
          id: grant_request_1_id,
          data_structure: %{current_version: %{name: "structure_1"}}
        },
        status: "cancelled"
      )

    [{link, header, content}] =
      EmailView.render(
        "grant_request_status_cancellation.html",
        %{
          event:
            build(:event,
              event: "grant_request_status_cancellation",
              resource_type: "grant_request_status",
              payload: payload
            )
        }
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    assert link =~ ~r|.*/grantRequests/#{grant_request_1_id}|
    assert header == "structure_1"

    assert [
             "Grant request cancellation",
             {"User:", nil},
             {"Status:", "cancelled"}
           ] = content
  end

  test "data structure event: renders data structure link: /structures/<data_structure_id>" do
    data_structure_id = 1234
    data_structure_event = "structure_tag_linked"

    payload =
      string_params_for(
        :payload,
        event: data_structure_event,
        data_structure_id: data_structure_id,
        tag: "tag1",
        comment: "comment1",
        resource: %{
          name: "name",
          path: ["p1", "p2"]
        }
      )

    [{link, header, content}] =
      EmailView.render(
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
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    assert link =~ ~r|.*/structures/#{data_structure_id}|
    assert header == "p1 > p2 > name"

    assert [
             {"Evento:", "Structure linked to tag"},
             {"Dominio:", nil},
             {"Etiqueta:", "tag1"},
             {"Comentarios:", "comment1"},
             {"Solicitante:", nil}
           ] = content
  end

  test "grant aproval event: renders grant request link: /grantRequest/<grant_request_id>" do
    grant_request_id = 1234
    grant_approval_event = "grant_approval"

    grant_request = %{
      "applicant_user" => %{
        "id" => 3,
        "name" => "foo user"
      },
      "grant_request_meta" => %{
        "access description" => "access description test",
        "access comment" => "test comment"
      },
      "grant_type" => "Data access",
      "data_structure" => %{
        "name" => "data structure test",
        "id" => 1234,
        "type" => "Database"
      }
    }

    payload =
      string_params_for(
        :payload,
        event: grant_approval_event,
        grant_request: grant_request,
        comment: "Test approval comment",
        status: "rejected",
        name: "structure_name"
      )

    [{link, header, content}] =
      EmailView.render(
        "#{grant_approval_event}.html",
        %{
          event:
            build(:event,
              resource_type: "grant_requests",
              resource_id: grant_request_id,
              event: grant_approval_event,
              payload: payload
            )
        }
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    assert link =~ ~r|.*/grantRequests/#{grant_request_id}|
    assert header == "structure_name"

    assert [
             {"Approver:", nil},
             {"Status:", "rejected"},
             {"Approver comments:", "Test approval comment"}
           ] = content
  end

  test "note event: renders note link: /structures/<data_structure_id>/notes" do
    data_structure_id = 1234
    note_event = "structure_note_pending_approval"

    payload =
      string_params_for(
        :payload,
        event: note_event,
        data_structure_id: data_structure_id,
        resource: %{
          name: "name",
          path: ["p1", "p2"]
        }
      )

    [{link, header, content}] =
      EmailView.render(
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
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    assert link =~ ~r|.*/structures/#{data_structure_id}/notes|
    assert header == "p1 > p2 > name"

    assert [
             {"Evento:", "Structure note pending approval"},
             {"Dominio:", nil}
           ] = content
  end

  test "remediation_created event: renders remediation link: /implementations/<implementation_id>/results/<rule_result_id>/remediation_plan" do
    implementation_id = 123
    rule_result_id = 456

    payload =
      string_params_for(
        :payload,
        domain_ids: [2],
        implementation_id: implementation_id,
        rule_result_id: rule_result_id,
        implementation_key: "implementation_key",
        date: "2000-10-10",
        content: %{"foo" => "bar"}
      )

    [{link, header, content}] =
      EmailView.render(
        "remediation_created.html",
        %{
          event:
            build(:event,
              event: "remediation_created",
              resource_type: "remediation",
              payload: payload
            )
        }
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Floki.parse_document!()
      |> EmailParser.parse_events()

    assert link =~
             ~r|.*/implementations/#{implementation_id}/results/#{rule_result_id}/remediation_plan|

    assert header == "Remediation plan"

    assert [
             {"Event:", "Remediation plan created"},
             {"Implementation:", "implementation_key"},
             {"Domains:", nil},
             {"Rule result date:", nil}
           ] = content
  end
end
