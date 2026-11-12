defmodule PersonalWebsite.MixProject do
  use Mix.Project

  def project do
    [
      app: :personal_website,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PersonalWebsite.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      {:earmark, "~> 1.4"},
      {:makeup_elixir, "~> 1.0"},
      {:extwitter, "~> 0.14"},
      {:timex, "~> 4.0"},
      {:tesla, "~> 1.15"},
      {:phoenix_live_view, "~> 1.1"},
      {:floki, ">= 0.38.0", only: :test},
      {:sendgrid, "~> 2.0"},
      {:stripity_stripe, "~> 3.2"},
      {:vapor, "~> 0.10.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "assets.deploy": [
        "esbuild default --minify",
        "cmd cp -r assets/css priv/static/css",
        "cmd cp -r assets/fonts priv/static/fonts",
        "cmd cp -r assets/sounds priv/static/sounds",
        "cmd cp -r assets/static/. priv/static/",
        "phx.digest"
      ]
    ]
  end
end
