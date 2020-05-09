defmodule PersonalWebsite.PostTest do
  use ExUnit.Case, async: true

  alias PersonalWebsite.Post

  describe "render/1" do
    test "turns markdown into HTML" do
      input = File.read!("posts/2020-5-1-local-metrics-aggregation-with-counters.md")

      assert %Post{
               body: body,
               date: date,
               description:
                 "Recently I needed to get a better picture of how my application's database connection pool was doing, but there was a bit of a hitch. DBConnection has a highly optimized queuing algorithm, but the downside of that optimization is that you can't get an accurate picture of the number of idle and busy connections in the pool at any given time like you can with Poolboy.",
               slug: "local-metrics-aggregation-with-counters",
               tags: ["Elixir", "Erlang", "Metrics", "Performance", "Telemetry"],
               title: "Local Metrics Aggregation With Counters",
               author: "Devon"
             } = Post.parse!("2020-5-1-local-metrics-aggregation-with-counters.md", input)

      assert date == NaiveDateTime.from_iso8601!("2020-05-01 00:18:00")
      assert body == """
      """
    end
  end
end
