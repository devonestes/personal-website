# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :personal_website, PersonalWebsiteWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "lKCdipsrLCP4LbjJBZrPXfSlwfO3Y/kVChOJVj/po/TTmsMBiQICgbXT/qGSFYYx",
  render_errors: [view: PersonalWebsiteWeb.ErrorView, accepts: ~w(html json)],
  live_view: [signing_salt: "LZKYtQXg"],
  pubsub_server: PersonalWebsite.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
