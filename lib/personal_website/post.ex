defmodule PersonalWebsite.Post do
  @enforce_keys [:slug, :author, :title, :body, :description, :tags, :date, :template]
  defstruct [:slug, :author, :title, :body, :description, :tags, :date, :template]

  alias PersonalWebsite.Highlighter

  def parse!(filename, contents) do
    slug =
      filename
      |> Path.split()
      |> Enum.take(-1)
      |> hd()
      |> String.split("-", parts: 4)
      |> List.last()
      |> Path.rootname()

    # Get all attributes from the contents
    contents = parse_contents(slug, contents)

    # And finally build the post struct
    struct!(__MODULE__, [slug: slug, author: "Devon", template: "show"] ++ contents)
  end

  defp parse_contents(_slug, contents) do
    [parts, body] = Regex.split(~r/^---(.*)---\n/ms, contents, include_captures: true, trim: true)

    parts
    |> String.trim()
    |> String.split("\n")
    |> List.delete_at(-1)
    |> List.delete_at(0)
    |> Enum.map(&parse_part/1)
    |> List.insert_at(0, {:body, body})
    |> Enum.map(&parse_attr/1)
  end

  defp parse_part(part) do
    [k, v] = Regex.split(~r/^(\w*): /, part, include_captures: true, trim: true)

    k =
      k
      |> String.trim_trailing(": ")
      |> String.to_existing_atom()

    {k, v}
  end

  defp parse_attr({:title, value}),
    do: {:title, String.trim(value)}

  defp parse_attr({:description, value}),
    do: {:description, String.trim(value)}

  defp parse_attr({:body, value}),
    do: {:body, value |> Earmark.as_html!() |> Highlighter.highlight_code_blocks()}

  defp parse_attr({:date, value}) do
    value = String.trim(value)
    [year, month, day_and_time] = String.split(value, "-")
    [day, time] = String.split(day_and_time, " ")

    date =
      NaiveDateTime.from_iso8601!(
        "#{year}-#{String.pad_leading(month, 2, "0")}-#{String.pad_leading(day, 2, "0")} #{time}"
      )

    {:date, date}
  end

  defp parse_attr({:tags, value}),
    do: {:tags, value |> String.split(" ") |> Enum.map(&String.trim/1) |> Enum.sort()}
end
