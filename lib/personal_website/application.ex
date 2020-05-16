defmodule PersonalWebsite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    twitter_prune()

    children =
      if Mix.env() == :dev do
        [
          PersonalWebsiteWeb.Endpoint,
          {Phoenix.PubSub, [name: PersonalWebsite.PubSub, adapter: Phoenix.PubSub.PG2]}
        ]
      else
        [PersonalWebsiteWeb.Endpoint]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PersonalWebsite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PersonalWebsiteWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp twitter_prune() do
    one_week_ago = DateTime.add(DateTime.utc_now(), -(60 * 60 * 24 * 7))

    Task.async(fn ->
      ExTwitter.configure(
        consumer_key: System.get_env("CONSUMER_KEY"),
        consumer_secret: System.get_env("CONSUMER_SECRET"),
        access_token: System.get_env("ACCESS_TOKEN"),
        access_token_secret: System.get_env("ACCESS_TOKEN_SECRET")
      )

      [screen_name: "devoncestes", count: 200]
      |> ExTwitter.user_timeline()
      |> Enum.filter(fn tweet ->
        created_at =
          Timex.parse!(tweet.created_at, "{WDshort} {Mshort} {0D} {h24}:{m}:{s} {Z} {YYYY}")

        DateTime.diff(created_at, one_week_ago) <= 0
      end)
      |> Enum.each(&ExTwitter.destroy_status(&1.id))

      [screen_name: "devoncestes", count: 200]
      |> ExTwitter.favorites()
      |> Enum.each(&ExTwitter.destroy_favorite(&1.id, []))
    end)
  end
end
