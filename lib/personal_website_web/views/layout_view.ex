defmodule PersonalWebsiteWeb.LayoutView do
  use PersonalWebsiteWeb, :view

  alias PersonalWebsite.Post

  @base_url "https://devonestes.com"
  @site_name "Devon C. Estes"
  @default_description "An (at least) monthly weblog about software"
  @default_image "/images/cropped_headshot.jpg"

  @doc """
  Returns the values used for the `<title>`, description, Open Graph and Twitter card tags.

  Blog posts get their own title, description, URL and (optionally) image so that link
  previews on LinkedIn, Slack, Twitter, etc. show the post rather than the generic site card.
  """
  def meta(%{post: %Post{title: title} = post}) when is_binary(title) do
    %{
      title: title,
      page_title: "#{title} | #{@site_name}",
      description: post.description || @default_description,
      url: "#{@base_url}/#{post.slug}",
      image: absolute_url(post.image || @default_image),
      large_image?: not is_nil(post.image),
      type: "article"
    }
  end

  def meta(_assigns) do
    %{
      title: @site_name,
      page_title: @site_name,
      description: @default_description,
      url: @base_url,
      image: absolute_url(@default_image),
      large_image?: false,
      type: "website"
    }
  end

  def site_name, do: @site_name

  defp absolute_url("http" <> _ = url), do: url
  defp absolute_url("/" <> _ = path), do: @base_url <> path
  defp absolute_url(path), do: "#{@base_url}/#{path}"
end
