defmodule TdAuditWeb.EmailViewTest do
  use TdAuditWeb.ConnCase, async: true
  alias Phoenix.HTML.Safe
  alias TdAuditWeb.EmailView

  test "renders rule_result_created.html using configured timezone" do
    payload =
      string_params_for(
        :payload,
        event: "rule_result_created",
        date: "2022-02-12T11:46:39Z"
      )

    assert EmailView.render(
             "rule_result_created.html",
             %{event: build(:event, event: "rule_result_created", payload: payload)}
           )
           |> Safe.to_iodata()
           |> IO.iodata_to_binary() =~ TdAudit.Helpers.shift_zone(payload["date"])
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

    email =
      EmailView.render(
        "rule_result_created.html",
        %{event: build(:event, event: "rule_result_created", payload: payload)}
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()

    # credo:disable-for-next-line
    assert email =~
             ~r|<a href=".*/implementations/#{implementation_id}/results".*>\n*\s*#{rule_name} : #{implementation_key}\n*\s*</a>|
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

    email =
      EmailView.render(
        "rule_result_created.html",
        %{event: build(:event, event: "rule_result_created", payload: payload)}
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()

    assert email =~
             ~r|<a href=".*/implementations/#{implementation_id}/results".*>\n*\s*#{implementation_key}\n*\s*</a>|
  end

  test "implementation created event: renders implementation link: /implementations/<implementation_id>" do
    implementation_id = 12_345

    payload =
      string_params_for(
        :payload,
        implementation_id: implementation_id
      )

    assert EmailView.render(
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
           |> IO.iodata_to_binary() =~ ~r|<a href=".*/implementations/#{implementation_id}"|
  end

  test "grant_request_group_creation event: renders grant requests links: /grant_requests/<id>" do
    grant_request_1_id = 361
    grant_request_2_id = 362

    payload =
      string_params_for(
        :payload,
        domain_ids: [2, 216],
        id: 252,
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

    binary =
      EmailView.render(
        "grant_request_group_creation.html",
        %{
          event:
            build(:event,
              event: "grant_request_group_creation",
              resource_type: "grant_request_groups",
              payload: payload
            )
        }
      )
      |> Safe.to_iodata()
      |> IO.iodata_to_binary()

    assert binary =~ ~r|<a href=".*/grant_requests/#{grant_request_1_id}"|
    assert binary =~ ~r|<a href=".*/grant_requests/#{grant_request_2_id}"|
  end

  test "grant_request_approvals event: renders grant requests links: /grant_requests/<id>" do
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

    binary =
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

    assert binary =~ ~r|<a href=".*/grant_requests/#{grant_request_1_id}"|
  end

  test "grant_request_status event: renders grant requests links: /grant_requests/<id>" do
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

    binary =
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

    assert binary =~ ~r|<a href=".*/grant_requests/#{grant_request_1_id}"|
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

  test "data structure event: renders data structure link: /structures/<data_structure_id>2" do
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
        status: "rejected"
      )

    assert EmailView.render(
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
           |> IO.iodata_to_binary() =~ ~r|<a href=".*/grant_requests/#{grant_request_id}"|
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
