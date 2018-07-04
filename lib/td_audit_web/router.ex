defmodule TdAuditWeb.Router do
  use TdAuditWeb, :router

  @endpoint_url "#{Application.get_env(:td_audit, TdAuditWeb.Endpoint)[:url][:host]}:#{Application.get_env(:td_audit, TdAuditWeb.Endpoint)[:url][:port]}"

  pipeline :api do
    plug TdAudit.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_secure do
    plug TdAudit.Auth.Pipeline.Secure
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :td_audit, swagger_file: "swagger.json"
  end

  scope "/api", TdAuditWeb do
    pipe_through :api
    get  "/ping", PingController, :ping
    post "/echo", EchoController, :echo
    post "/audits", AuditController, :create
  end

  scope "/api", TdAuditWeb do
    pipe_through [:api, :api_secure]
    resources "/events", EventController, except: [:new, :edit]
  end

  def swagger_info do
  %{
    schemes: ["http"],
    info: %{
      version: "1.0",
      title: "TdAudit"
    },
    "host": @endpoint_url,
    "basePath": "/api",
    "securityDefinitions":
      %{
        bearer:
        %{
          "type": "apiKey",
          "name": "Authorization",
          "in": "header",
        }
    },
    "security": [
      %{
       bearer: []
      }
    ]
  }
end
end
