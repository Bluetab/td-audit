defmodule TdAuditWeb.Router do
  use TdAuditWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TdAuditWeb do
    pipe_through :api
    resources "/events", EventController, except: [:new, :edit]
    post "/audit", AuditController, :create
  end
end
