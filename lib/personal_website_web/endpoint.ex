defmodule PersonalWebsiteWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :personal_website

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_personal_website_key",
    signing_salt: "8A0AnXfD"
  ]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :personal_website,
    gzip: false,
    only: ~w(css fonts images sounds js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug PersonalWebsiteWeb.Router

  def init(_, config) do
    case System.get_env("PORT") do
      port when is_binary(port) ->
        port = String.to_integer(port)

        http =
          config
          |> Keyword.get(:http, [])
          |> Keyword.put(:port, port)

        url =
          config
          |> Keyword.get(:url, [])
          |> Keyword.put(:port, port)

        config =
          config
          |> Keyword.put(:http, http)
          |> Keyword.put(:url, url)

        {:ok, config}

      _ ->
        {:ok, config}
    end
  end
end
