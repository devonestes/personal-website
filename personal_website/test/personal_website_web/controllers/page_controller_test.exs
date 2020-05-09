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
    response = html_response(conn, 200)
  end

  defp assert_equal_strings(left, right) do
    assert String.replace(left, ~r/[[:space:]]/, "") =~ String.replace(right, ~r/[[:space:]]/, "")
  end
end
