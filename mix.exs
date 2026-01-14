defmodule PersonalWebsite.MixProject do
  use Mix.Project

  def project do
    [
      app: :personal_website,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
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
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:earmark, "~> 1.3"},
      {:makeup_elixir, "~> 0.14"},
      {:extwitter, "~> 0.12"},
      {:timex, "~> 3.6.1"},
      {:tesla, "~> 1.3.0"},
      {:phoenix_live_view, "~> 0.17"},
      {:floki, ">= 0.30.0", only: :test},
      {:sendgrid, "~> 2.0"},
      {:stripity_stripe, "~> 2.17"},
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
