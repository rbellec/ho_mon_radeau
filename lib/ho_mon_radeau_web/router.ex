defmodule HoMonRadeauWeb.Router do
  use HoMonRadeauWeb, :router

  use Kaffy.Routes,
    scope: "/kaffy",
    pipe_through: [:browser, :require_authenticated_user, :require_admin_user]

  import HoMonRadeauWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HoMonRadeauWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HoMonRadeauWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Public LiveView routes with optional user scope
  live_session :public, on_mount: [{HoMonRadeauWeb.UserAuth, :mount_current_scope}] do
    scope "/", HoMonRadeauWeb do
      pipe_through :browser

      live "/radeaux", RaftLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HoMonRadeauWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ho_mon_radeau, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HoMonRadeauWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", HoMonRadeauWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", HoMonRadeauWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  # Routes requiring authenticated user (not necessarily validated)
  live_session :authenticated,
    on_mount: [{HoMonRadeauWeb.UserAuth, :require_authenticated_user}] do
    scope "/", HoMonRadeauWeb do
      pipe_through :browser

      live "/mon-radeau", RaftLive.MyCrew, :show
      live "/mon-profil", ProfileLive, :show
    end
  end

  # Routes requiring validated user
  live_session :validated,
    on_mount: [
      {HoMonRadeauWeb.UserAuth, :require_authenticated_user},
      {HoMonRadeauWeb.UserAuth, :require_validated_user}
    ] do
    scope "/", HoMonRadeauWeb do
      pipe_through :browser

      live "/fiche-inscription", RegistrationFormLive.Index, :index
      live "/radeaux/nouveau", RaftLive.New, :new
    end
  end

  # Public raft detail page (must be after /radeaux/nouveau to avoid slug conflict)
  live_session :public_raft, on_mount: [{HoMonRadeauWeb.UserAuth, :mount_current_scope}] do
    scope "/", HoMonRadeauWeb do
      pipe_through :browser

      live "/radeaux/:slug", RaftLive.Show, :show
    end
  end

  # Admin routes
  live_session :admin,
    on_mount: [
      {HoMonRadeauWeb.UserAuth, :require_authenticated_user},
      {HoMonRadeauWeb.UserAuth, :require_admin_user}
    ] do
    scope "/admin", HoMonRadeauWeb.Admin, as: :admin do
      pipe_through :browser

      live "/utilisateurs", UserLive.Index, :index
      live "/utilisateurs/:id", UserLive.Show, :show
      live "/fiches", RegistrationFormLive.Index, :index
      live "/fiches/:id", RegistrationFormLive.Show, :show
      live "/radeaux", RaftLive.Index, :index
      live "/equipes-transverses", TransverseTeamLive.Index, :index
      live "/equipes-transverses/:id", TransverseTeamLive.Show, :show
      live "/bidons", DrumsLive.Index, :index
    end
  end

  scope "/", HoMonRadeauWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
