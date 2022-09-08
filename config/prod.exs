import Config

config :personal_website, PersonalWebsiteWeb.Endpoint,
  url: [host: "devonestes.com"],
  http: [port: 80],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  debug_errors: false

config :logger, level: :info
