defmodule MicrokernelWeb.Router do
  use MicrokernelWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MicrokernelWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :require_auth do
    plug MicrokernelWeb.Plugs.EnsureAuth
  end

  pipeline :require_admin do
    plug MicrokernelWeb.Plugs.Authorize, roles: ["admin"]
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug MicrokernelWeb.Plugs.Auth
  end

  scope "/", MicrokernelWeb do
    pipe_through :browser

    live "/login", AuthLive.Login, :new
    post "/login", AuthController, :login
    post "/logout", AuthController, :logout
  end

  scope "/", MicrokernelWeb do
    pipe_through [:browser, :require_auth]

    live "/", DeviceLive.Index, :index
    live "/devices/:id", DeviceLive.Show, :show
    live "/devices/:id/charts", DeviceLive.Charts, :charts
    live "/metrics", MetricsLive, :index
  end

  scope "/api", MicrokernelWeb.Api, as: :api do
    pipe_through :api

    resources "/devices", DeviceController, only: [:index, :show]
    get "/devices/:device_id/telemetry", TelemetryController, :index
    get "/devices/:device_id/telemetry/latest", TelemetryController, :latest
    get "/devices/:device_id/telemetry/export", ExportController, :export_telemetry
    get "/devices/export", ExportController, :export_devices
    post "/devices/:device_id/update", OTAController, :create
    get "/devices/:device_id/update/status", OTAController, :status
  end

  scope "/api/admin", MicrokernelWeb.Api, as: :api_admin do
    pipe_through [:api]

    resources "/api_keys", ApiKeyController, only: [:index, :create]
    resources "/organizations", OrganizationController, only: [:index, :show, :create]
  end

  scope "/", MicrokernelWeb do
    pipe_through :browser
    get "/metrics", MetricsController, :index
    get "/api/docs", SwaggerController, :swaggerui
  end

  scope "/api", MicrokernelWeb do
    pipe_through :api
    get "/swagger.json", SwaggerController, :swagger_json
  end

  if Application.compile_env(:microkernel, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MicrokernelWeb.Telemetry
    end
  end
end

