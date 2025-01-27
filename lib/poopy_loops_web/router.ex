defmodule PoopyLoopsWeb.Router do
  use PoopyLoopsWeb, :router

  import PoopyLoopsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PoopyLoopsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :login_layout do
    plug :put_root_layout, {PoopyLoopsWeb.Layouts, :login}
    plug :put_layout, false
  end

  scope "/", PoopyLoopsWeb do
    pipe_through :browser

    get "/", RedirectController, :redirect_to_playlists
  end

  scope "/auth/google", PoopyLoopsWeb do
    pipe_through [:browser]
    get "/", GoogleAuthController, :request
    get "/callback", GoogleAuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", PoopyLoopsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:poopy_loops, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PoopyLoopsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", PoopyLoopsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated, :login_layout]

    get "/users/log_in", UserSessionController, :login

    # live_session :redirect_if_user_is_authenticated,
    #   on_mount: [{PoopyLoopsWeb.UserAuth, :redirect_if_user_is_authenticated}] do
    # end
  end

  scope "/", PoopyLoopsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PoopyLoopsWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      # live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/playlists", PlaylistLive.Index, :index
      live "/playlists/new", PlaylistLive.Index, :new
      live "/playlists/:id/edit", PlaylistLive.Index, :edit
      live "/playlists/:id", PlaylistLive.Show, :show
      live "/playlists/:id/show/edit", PlaylistLive.Show, :edit
    end
  end

  scope "/", PoopyLoopsWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PoopyLoopsWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
