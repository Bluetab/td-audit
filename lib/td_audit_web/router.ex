defmodule TdAuditWeb.Router do
  use TdAuditWeb, :router

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  pipeline :api do
    plug(TdAudit.Auth.Pipeline.Unsecure)
    plug(:accepts, ["json"])
  end

  pipeline :api_secure do
    plug(TdAudit.Auth.Pipeline.Secure)
  end

  scope "/api/swagger" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :td_audit, swagger_file: "swagger.json")
  end

  scope "/api", TdAuditWeb do
    pipe_through(:api)
    get("/ping", PingController, :ping)
    post("/echo", EchoController, :echo)
  end

  scope "/api", TdAuditWeb do
    pipe_through([:api, :api_secure])
    resources("/events", EventController, only: [:index, :show])
    resources("/events/search", EventSearchController, only: [:create])
    resources("/subscribers", SubscriberController, except: [:new, :edit, :update])
    resources("/subscriptions", SubscriptionController, except: [:new, :edit])
    post("/subscriptions/user/me/search", SubscriptionController, :index_by_user)
    resources("/notifications", NotificationController, only: [:create])
    post("/notifications/:id/read", NotificationController, :read)
    post("/notifications/user/me/search", NotificationController, :index_by_user)
  end

  def swagger_info do
    %{
      schemes: ["http", "https"],
      info: %{
        version: Application.spec(:td_audit, :vsn),
        title: "Truedat Audit Service"
      },
      securityDefinitions: %{
        bearer: %{
          type: "apiKey",
          name: "Authorization",
          in: "header"
        }
      },
      security: [
        %{
          bearer: []
        }
      ]
    }
  end
end
