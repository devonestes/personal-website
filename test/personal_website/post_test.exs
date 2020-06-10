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

      assert body =~ String.trim("""
      But I’m a big fan of keeping things simple when it comes to ops, and setting up another thing that
      involves configuration files is the last thing I want to do. Luckily, there’s a way we can do this
      really well and easily with just what’s built-in to Erlang (starting with OTP 21.2) and Elixir.</p>
      <h2>The solution</h2>
      <p>Before I go into my solution, I should note that the gist of this solution was José’s and not
      mine. There’s no way I’d come up with something this good on my own, so thanks to him for the tip
      on how to make this really efficient. So, below is a GenServer that you can use as a local
      aggregate server, but in OTP!</p>
      <pre><code class=\"nohighlight makeup elixir\"><span class=\"kd\">defmodule</span><span class=\"w\"> </span><span class=\"nc\">Telemetry.LocalAggregation</span><span class=\"w\"> </span><span class=\"k\"
      """)
    end
  end
end
