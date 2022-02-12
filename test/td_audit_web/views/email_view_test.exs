defmodule TdAuditWeb.EmailViewTest do
  use TdAuditWeb.ConnCase, async: true
  alias TdAuditWeb.EmailView

  test "renders rule_result_created.html using configured timezone" do
    payload = string_params_for(
      :payload,
      date: "2022-02-12T11:46:39Z",
      result_type: "percentage",
      goal: 10.0,
      minimum: 0.0,
      errors: 0,
      records: 1,
      result: 100.00,
    )

    assert EmailView.render("rule_result_created.html",
      %{event: build(:event, event: "rule_result_created", payload: payload)}
    )
    |> Phoenix.HTML.Safe.to_iodata
    |> IO.iodata_to_binary =~ TdAudit.Helpers.shift_zone(payload["date"])
  end
end
