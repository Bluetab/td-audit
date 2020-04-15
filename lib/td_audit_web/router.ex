defmodule TdAuditWeb.Router do
  use TdAuditWeb, :router

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
    post("/audits", AuditController, :create)
  end

  scope "/api", TdAuditWeb do
    pipe_through([:api, :api_secure])
    resources("/events", EventController, except: [:new, :edit])
    resources("/subscriptions", SubscriptionController, except: [:new, :edit])
    resources("/subscriptions", SubscriptionsController, singleton: true, only: [:update])

    resources("/notifications_system/configurations", ConfigurationController,
      except: [:new, :edit]
    )
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
