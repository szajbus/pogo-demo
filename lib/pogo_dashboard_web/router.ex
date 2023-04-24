defmodule PogoDashboardWeb.Router do
  use PogoDashboardWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {PogoDashboardWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", PogoDashboardWeb do
    pipe_through(:browser)

    live("/", PogoLive, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", PogoDashboardWeb do
  #   pipe_through :api
  # end
end
