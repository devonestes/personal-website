use Mix.Config

config :personal_website, PersonalWebsiteWeb.Endpoint,
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

config :sendgrid, api_key: Map.fetch!(System.get_env(), "SENDGRID_API_KEY"), enable_sandbox: false
