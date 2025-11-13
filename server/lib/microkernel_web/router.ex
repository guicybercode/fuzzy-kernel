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

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MicrokernelWeb do
    pipe_through :browser

    live "/", DeviceLive.Index, :index
    live "/devices/:id", DeviceLive.Show, :show
  end

  if Application.compile_env(:microkernel, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MicrokernelWeb.Telemetry
    end
  end
end

