defmodule TdAuditWeb.Router do
  use TdAuditWeb, :router

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  pipeline :api do
    plug TdAudit.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug TdAudit.Auth.Pipeline.Secure
  end

  scope "/api", TdAuditWeb do
    pipe_through :api
    get("/ping", PingController, :ping)
    post("/echo", EchoController, :echo)
  end

  scope "/api", TdAuditWeb do
    pipe_through [:api, :api_auth]
    resources("/events", EventController, only: [:index, :show])
    resources("/events/search", EventSearchController, only: [:create])
    resources("/subscribers", SubscriberController, except: [:new, :edit, :update])
    resources("/subscriptions", SubscriptionController, except: [:new, :edit])
    post("/subscriptions/user/me/search", SubscriptionController, :index_by_user)
    resources("/notifications", NotificationController, only: [:create])
    post("/notifications/:id/read", NotificationController, :read)
    post("/notifications/user/me/search", NotificationController, :index_by_user)

    get("/upload_jobs/", UploadJobController, :index)
    get("/upload_jobs/:id", UploadJobController, :show)
  end
end
