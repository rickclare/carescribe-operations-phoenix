defmodule OperationsWeb.Router do
  use OperationsWeb, :router

  import OperationsWeb.OperatorAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OperationsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_operator
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OperationsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/operators/auth", OperationsWeb do
    pipe_through :browser

    get "/:provider", OperatorAuthController, :request
    get "/:provider/callback", OperatorAuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", OperationsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:operations, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OperationsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", OperationsWeb do
    pipe_through [:browser, :require_authenticated_operator]

    live_session :require_authenticated_operator,
      on_mount: [{OperationsWeb.OperatorAuth, :require_authenticated}] do
      live "/operators/settings", OperatorLive.Settings, :edit
      live "/operators/settings/confirm-email/:token", OperatorLive.Settings, :confirm_email
    end

    post "/operators/update-password", OperatorSessionController, :update_password
  end

  scope "/", OperationsWeb do
    pipe_through [:browser]

    live_session :current_operator,
      on_mount: [{OperationsWeb.OperatorAuth, :mount_current_scope}] do
      live "/operators/register", OperatorLive.Registration, :new
      live "/operators/log-in", OperatorLive.Login, :new
      live "/operators/log-in/:token", OperatorLive.Confirmation, :new
    end

    post "/operators/log-in", OperatorSessionController, :create
    delete "/operators/log-out", OperatorSessionController, :delete
  end
end
