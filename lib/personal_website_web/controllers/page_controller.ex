defmodule PersonalWebsiteWeb.PageController do
  use PersonalWebsiteWeb, :controller

  alias PersonalWebsite.Posts

  def index(conn, params) do
    {posts, page, num_pages} = Posts.list_posts(params["page"])
    posts = Enum.map(posts, fn post -> Map.update!(post, :date, &format_date/1) end)
    render(conn, "index.html", posts: posts, page: page, num_pages: num_pages)
  end

  def show(conn, params) do
    conn =
      case params["slug"] do
        "resume" -> put_layout(conn, "empty.html")
        _ -> conn
      end

    post = Posts.get_post!(params["slug"])
    post = Map.update!(post, :date, &format_date/1)
    render(conn, "#{post.template}.html", post: post)
  end

  def index_by_tag(conn, params) do
    {posts, page, num_pages} = Posts.get_posts_by_tag!(params["tag"], params["page"])
    render(conn, "index.html", posts: posts, page: page, num_pages: num_pages)
  end

  defp format_date(date) do
    "#{date.day} #{month_for(date.month)} #{date.year}"
  end

  defp month_for(1), do: "Jan"
  defp month_for(2), do: "Feb"
  defp month_for(3), do: "Mar"
  defp month_for(4), do: "Apr"
  defp month_for(5), do: "May"
  defp month_for(6), do: "Jun"
  defp month_for(7), do: "Jul"
  defp month_for(8), do: "Aug"
  defp month_for(9), do: "Sep"
  defp month_for(10), do: "Oct"
  defp month_for(11), do: "Nov"
  defp month_for(12), do: "Dec"
end
