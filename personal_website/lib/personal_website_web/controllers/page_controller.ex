defmodule PersonalWebsiteWeb.PageController do
  use PersonalWebsiteWeb, :controller

  alias PersonalWebsite.Posts

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, params) do
    render(conn, "show.html", body: Posts.get_post(params["slug"]))
  end
end
