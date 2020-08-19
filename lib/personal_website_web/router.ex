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
    live "/bus", Bus
    get "/tag/:tag", PageController, :index_by_tag
    get "/:slug", PageController, :show
  end
end
