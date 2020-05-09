defmodule PersonalWebsiteWeb.PageControllerTest do
  use PersonalWebsiteWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    response = html_response(conn, 200)

    assert response =~
      """
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8" />
          <meta http-equiv="X-UA-Compatible" content="IE=edge" />

          <title>Devon C. Estes</title>
          <meta name="description" content="Devon C. Estes" />
          <meta name="HandheldFriendly" content="True" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />

          <link rel="shortcut icon" href="/assets/images/favicon.ico" >

          <link rel="alternate" type="application/rss+xml" title="Devon C. Estes" href="/feed.xml" />

          <link rel="stylesheet" type="text/css" href="/assets/css/screen.css" />
          <link rel="stylesheet" type="text/css" href="/assets/css/codefund.css" />
          <link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family=Merriweather:300,700,700italic,300italic|Open+Sans:700,400" />
          <link rel="stylesheet" type="text/css" href="/assets/css/syntax.css" />

          <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.3.0/styles/default.min.css">
          <style>.hljs { background: none; }</style>
          <script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.3.0/highlight.min.js"></script>
          <script>hljs.initHighlightingOnLoad();</script>

          <meta property="og:site_name" content="Devon C. Estes" />
          <meta property="og:type" content="website" />
          <meta property="og:title" content="Devon C. Estes" />
          <meta property="og:description" content="" />
          <meta property="og:url" content="/" />
          <meta property="og:image" content="/assets/images/logo.png" />

          <meta name="twitter:card" content="summary">
          <meta name="twitter:site" content="@devoncestes">
          <meta name="twitter:creator" content="@devoncestes">
          <meta name="twitter:title" content="Devon C. Estes">
          <meta name="twitter:url" content="http://localhost:4000/">
          <meta name="twitter:text:description" content="An (at least) monthly weblog about software">
          <meta name="twitter:image:src" content="http://localhost:4000/assets/images/cropped_headshot.jpg">
      """

    assert response =~
      """
          <script type=\"text/javascript\" src=\"https://code.jquery.com/jquery-1.11.3.min.js\"></script>
          <script type=\"text/javascript\" src=\"/assets/js/jquery.fitvids.js\"></script>
          <script type=\"text/javascript\" src=\"/assets/js/index.js\"></script>
          <script src=\"https://codefund.io/scripts/c073469c-dfa9-4c80-89f1-4c46166782f3/embed.js?template=horizontal\"></script>
      """

    assert response =~
      """
          <div class="nav">
            <h3 class="nav-title">Menu</h3>
            <a href="#" class="nav-close">
                <span class="hidden">Close</span>
            </a>
            <ul>
                <li class="nav-home  nav-current" role="presentation"><a href="/">Home</a></li>
                <li class="nav-about " role="presentation"><a href="/about">About Me</a></li>
                <li class="nav-elixir " role="presentation"><a href="/tag/Elixir">On Elixir</a></li>
                <li class="nav-ruby " role="presentation"><a href="/tag/Ruby">On Ruby</a></li>
            </ul>
            <a class="subscribe-button icon-feed" href="/feed.xml">Subscribe</a>
          </div>
          <span class="nav-cover"></span>
      """

    assert response =~
      """
            <nav class="pagination" role="pagination">
              <span class="page-number"> Page 1 of 7 </span>
              <a class="older-posts" href="/page2/" title="Next Page">Older Posts &raquo;</a>
            </nav>
      """
  end
end
