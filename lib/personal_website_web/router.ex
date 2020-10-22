defmodule PersonalWebsiteWeb.Router do
  use PersonalWebsiteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {PersonalWebsiteWeb.LayoutView, :root}
  end

  scope "/", PersonalWebsiteWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/retirement", RetirementController, :show
    get "/muzak", MuzakController, :info
    get "/muzak/subscribe", MuzakController, :signup
    get "/muzak/success", MuzakController, :get_credentials
    get "/muzak/cancel", MuzakController, :cancel
    get "/muzak/manage", MuzakController, :manage
    live "/bus", Bus
    get "/feed.xml", PageController, :rss_feed
    get "/tag/:tag", PageController, :index_by_tag
    get "/:slug", PageController, :show
  end
end
