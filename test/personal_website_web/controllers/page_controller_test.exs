defmodule PersonalWebsiteWeb.PageControllerTest do
  use PersonalWebsiteWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    response = html_response(conn, 200)

    assert_equal_strings(
      response,
      """
      <meta name="description" content="Devon C. Estes" />
      """
    )
  end

  test "GET /:slug", %{conn: conn} do
    conn = get(conn, "/local-metrics-aggregation-with-counters")
    assert html_response(conn, 200) =~ String.trim("""
    <header class=\"main-header post-head no-cover\">\n  <nav class=\"main-nav  clearfix\">\n    <a class=\"blog-logo\" href=\"/\"><img src=\"/images/logo.png\" alt=\"Blog Logo\"></a>\n      <a class=\"menu-button icon-menu\" href=\"#\"><span class=\"word\">Menu</span></a>\n  </nav>\n</header>\n<main class=\"content\" role=\"main\">\n  <article class=\"post tag-test tag-content\">\n    <header class=\"post-header\">\n      <h1 class=\"post-title\">Local Metrics Aggregation With Counters</h1>\n      <section class=\"post-meta\">\n        <time class=\"post-date\" datetime=\"1 May 2020\">1 May 2020</time>\n        Devon C. Estes on \n          <a href=\"/tag/Elixir\">Elixir</a>\n          <a href=\"/tag/Erlang\">Erlang</a>\n          <a href=\"/tag/Metrics\">Metrics</a>\n          <a href=\"/tag/Performance\">Performance</a>\n          <a href=\"/tag/Telemetry\">Telemetry</a>\n      </section>\n      <div id=\"codefund_ad\"></div>\n    </header>\n\n    <section class=\"post-content\">
    """)
  end

  defp assert_equal_strings(left, right) do
    assert String.replace(left, ~r/[[:space:]]/, "") =~ String.replace(right, ~r/[[:space:]]/, "")
  end
end
