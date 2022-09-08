import Config

config :personal_website, PersonalWebsiteWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
