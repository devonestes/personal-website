use Mix.Config

config :personal_website, PersonalWebsiteWeb.Endpoint,
  url: [host: "www.devonestes.com"],
  http: [port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

config :logger, level: :info

config :sendgrid, api_key: Map.fetch!(System.get_env(), "SENDGRID_API_KEY"), enable_sandbox: false
