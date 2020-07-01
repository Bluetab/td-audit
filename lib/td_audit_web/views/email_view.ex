defmodule TdAuditWeb.EmailView do
  use TdAuditWeb, :view

  require Logger

  def render("ingest_sent_for_approval.html", %{event: event}) do
    render("ingest_sent_for_approval.html",
      user: user_name(event),
      name: ingest_name(event),
      domains: domain_path(event),
      uri: uri(event)
    )
  end

  def render("rule_result_created.html", %{event: %{payload: payload} = event}) do
    values =
      ["goal", "minimum", "errors", "records", "result"]
      |> Enum.map(&{&1, format_number(payload, &1)})
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> {translate(k), v} end)

    render("rule_result_created.html",
      name: rule_implementation_name(event),
      values: values,
      domains: domain_path(event),
      date: payload["date"],
      uri: uri(event)
    )
  end

  def render("comment_created.html", %{event: %{payload: payload} = event}) do
    render("comment_created.html",
      user: user_name(event),
      name: payload["resource_name"],
      domains: domain_path(event),
      comment: payload["content"],
      uri: uri(event)
    )
  end

  def render(template, %{event: event}) do
    Logger.warn("Template #{template} not supported")

    event
    |> Map.take([:event, :payload])
    |> Jason.encode!()
  end

  defp ingest_name(%{payload: %{"name" => name}}), do: name
  defp ingest_name(_), do: nil

  defp rule_implementation_name(%{
         payload: %{"name" => name, "implementation_key" => implementation_key}
       }) do
    Enum.join([name, implementation_key], " : ")
  end

  defp rule_implementation_name(_), do: nil

  defp format_number(%{"result_type" => result_type} = payload, key) do
    format =
      if key in ["errors", "records"] do
        "number"
      else
        result_type
      end

    payload
    |> Map.get(key)
    |> format_number(format)
  end

  defp format_number(nil, _), do: nil

  defp format_number(value, "percentage") do
    Number.Percentage.number_to_percentage(value)
  end

  defp format_number(value, _format) do
    Number.Delimit.number_to_delimited(value)
  end

  defp user_name(%{user: %{full_name: full_name}}), do: full_name
  defp user_name(_), do: nil

  defp domain_path(%{payload: %{"domain_ids" => domain_ids}}) do
    domain_ids
    |> Enum.reverse()
    |> Enum.map(&TdCache.TaxonomyCache.get_domain/1)
    |> Enum.filter(& &1)
    |> Enum.map(& &1.name)
    |> Enum.join(" › ")
  end

  defp domain_path(_), do: nil

  defp uri(%{
         resource_type: "comment",
         payload: %{"resource_type" => "ingest", "version_id" => id}
       }) do
    Enum.join([host_name(), "ingests", id], "/")
  end

  defp uri(%{
         resource_type: "comment",
         payload: %{"resource_type" => "business_concept", "version_id" => id}
       }) do
    Enum.join([host_name(), "concepts", id], "/")
  end

  defp uri(%{resource_type: "ingest", payload: %{"id" => id}}) do
    Enum.join([host_name(), "ingests", id], "/")
  end

  defp uri(%{
         resource_type: "rule_result",
         payload: %{"rule_id" => rule_id, "implementation_id" => implementation_id}
       }) do
    Enum.join(
      [host_name(), "rules", rule_id, "implementations", implementation_id, "results"],
      "/"
    )
  end

  defp uri(_), do: nil

  defp translate("goal"), do: "Target"
  defp translate("minimum"), do: "Threshold"
  defp translate("records"), do: "Record Count"
  defp translate("errors"), do: "Error Count"
  defp translate("result"), do: "Result"

  defp host_name do
    Application.fetch_env!(:td_audit, :host_name)
  end
end
