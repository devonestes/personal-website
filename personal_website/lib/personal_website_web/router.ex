defmodule PersonalWebsiteWeb.Router do
  use PersonalWebsiteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", PersonalWebsiteWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/about", PageController, :about
    get "/:slug", PageController, :show
    get "/tag/:tag", PageController, :index_by_tag
  end
end