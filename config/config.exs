# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :personal_website, PersonalWebsiteWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "lKCdipsrLCP4LbjJBZrPXfSlwfO3Y/kVChOJVj/po/TTmsMBiQICgbXT/qGSFYYx",
  render_errors: [view: PersonalWebsiteWeb.ErrorView, accepts: ~w(html json)],
  live_view: [signing_salt: "LZKYtQXg"],
  pubsub_server: PersonalWebsite.PubSub

config :personal_website, :mix_env, Mix.env()

config :sendgrid, api_key: "fake_api_key", enable_sandbox: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{Mix.env()}.exs"
