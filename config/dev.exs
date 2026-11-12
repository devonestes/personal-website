import Config

config :personal_website, PersonalWebsiteWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg|wav)$",
      ~r"lib/personal_website_web/(live|views)/.*(ex)$",
      ~r"lib/personal_website_web/templates/.*(eex)$",
      ~r"posts/.*(md)$",
      ~r"pages/.*(html)$"
    ]
  ],
  pubsub_server: PersonalWebsite.PubSub

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
