defmodule TdAuditWeb.ConfigurationView do
  use TdAuditWeb, :view
  alias TdAuditWeb.ConfigurationView

  def render("index.json", %{notifications_system_configuration: notifications_system_configuration}) do
    %{data: render_many(notifications_system_configuration, ConfigurationView, "configuration.json")}
  end

  def render("show.json", %{configuration: configuration}) do
    %{data: render_one(configuration, ConfigurationView, "configuration.json")}
  end

  def render("configuration.json", %{configuration: configuration}) do
    %{id: configuration.id,
      event: configuration.event,
      settings: configuration.settings}
  end
end
