defmodule TdAuditWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use TdAuditWeb, :controller
      use TdAuditWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller(log \\ :info) do
    quote bind_quoted: [log: log] do
      use Phoenix.Controller, namespace: TdAuditWeb, log: log
      import Plug.Conn
      import TdAuditWeb.Gettext
      alias TdAuditWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/td_audit_web/templates",
        namespace: TdAuditWeb

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import TdAuditWeb.ErrorHelpers
      import TdAuditWeb.Gettext
      alias TdAuditWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  # Custom log level for controllers
  defmacro __using__([:controller = which, log]) do
    apply(__MODULE__, which, [log])
  end
end
