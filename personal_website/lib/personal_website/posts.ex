defmodule PersonalWebsite.Posts do
  alias PersonalWebsite.Post

  defmodule NotFoundError do
    defexception [:message, plug_status: 404]
  end

  for app <- [:earmark, :makeup_elixir] do
    Application.ensure_all_started(app)
  end

  posts_paths = "posts/**/*.md" |> Path.wildcard() |> Enum.sort()

  posts =
    for post_path <- posts_paths do
      @external_resource Path.relative_to_cwd(post_path)
      Post.parse!(post_path, File.read!(post_path))
    end

  @posts Enum.sort_by(posts, & &1.date, {:desc, NaiveDateTime})

  @tags posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  def list_posts(nil), do: list_posts("1")
  def list_posts(page) do
    page = String.to_integer(page)
    posts = Enum.chunk_every(@posts, 5)
    {Enum.at(posts, page - 1), page, length(posts)}
  end

  def get_post!(slug) do
    case Enum.find(@posts, &(&1.slug == slug)) do
      nil -> raise NotFoundError, "Post not found"
      post -> post
    end
  end

  def list_tags, do: @tags

  def get_posts_by_tag!(tag, nil) do
    get_posts_by_tag!(tag, "1")
  end

  def get_posts_by_tag!(tag, page) do
    page = String.to_integer(page)
    case Enum.filter(@posts, &(tag in &1.tags)) do
      [] ->
        raise NotFoundError, "posts with tag=#{tag} not found"

      posts ->
        posts = Enum.chunk_every(posts, 5)
        {Enum.at(posts, page - 1), page, length(posts)}
    end
  end
end
