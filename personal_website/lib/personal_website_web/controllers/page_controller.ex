defmodule PersonalWebsiteWeb.PageController do
  use PersonalWebsiteWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
