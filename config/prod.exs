use Mix.Config

config :personal_website, PersonalWebsiteWeb.Endpoint,
  url: [host: "devonestes.com"],
  http: [port: 80],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  debug_errors: false,
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

config :logger, level: :info

config :sendgrid, api_key: Map.fetch!(System.get_env(), "SENDGRID_API_KEY"), enable_sandbox: false
