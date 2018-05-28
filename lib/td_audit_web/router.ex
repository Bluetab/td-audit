defmodule TdAuditWeb.Router do
  use TdAuditWeb, :router

  pipeline :api do
    plug TdAudit.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_secure do
    plug TdAudit.Auth.Pipeline.Secure
  end

  scope "/api", TdAuditWeb do
    pipe_through :api
    post "/audits", AuditController, :create
  end

  scope "/api", TdAuditWeb do
    pipe_through [:api, :api_secure]
    resources "/events", EventController, except: [:new, :edit]
  end
end
