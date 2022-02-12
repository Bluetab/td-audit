defmodule TdAudit.Helpers do
  def shift_zone(date_utc_string, time_zone \\ Application.get_env(:td_audit, :time_zone)) do
      date_utc_string
      |> DateTime.from_iso8601
      |> (fn {:ok, date_utc, _} -> date_utc  end).()
      |> DateTime.shift_zone(time_zone)
      |> (fn {:ok, datetime} -> datetime end).()
      |> DateTime.to_iso8601
  end
end
