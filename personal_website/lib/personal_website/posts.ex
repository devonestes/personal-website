defmodule PersonalWebsite.Posts do
  alias PersonalWebsite.Post

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

  def list_posts() do
    @posts
  end

  def get_post(slug) do
    Enum.find(@posts, &(&1.slug == slug))
  end

  defmodule NotFoundError do
    defexception [:message, plug_status: 404]
  end

  @tags posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  def list_tags do
    @tags
  end

  def get_posts_by_tag!(tag) do
    case Enum.filter(list_posts(), &(tag in &1.tags)) do
      [] -> raise NotFoundError, "posts with tag=#{tag} not found"
      posts -> posts
    end
  end
end
