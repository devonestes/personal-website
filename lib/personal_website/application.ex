defmodule PersonalWebsite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SendGrid.{Email, Mail}

  def start(_type, _args) do
    Vapor.load!([%Vapor.Provider.Dotenv{overwrite: true}])
    Application.put_env(:personal_website, :gitea_token, System.fetch_env!("GITEA_API_TOKEN"))
    Application.put_env(:personal_website, :git_host, System.fetch_env!("GIT_HOST"))
    Application.put_env(:personal_website, :muzak_price_id, System.fetch_env!("PRICE_ID"))

    Application.put_env(
      :personal_website,
      :stripe_public_key,
      System.fetch_env!("STRIPE_PUBLIC_KEY")
    )

    Application.put_env(:stripity_stripe, :api_key, System.fetch_env!("STRIPE_SECRET_KEY"))

    twitter_prune()

    children =
      if Application.get_env(:personal_website, :mix_env) == :dev do
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
    if System.get_env("CONSUMER_KEY") do
      ExTwitter.configure(
        consumer_key: System.get_env("CONSUMER_KEY"),
        consumer_secret: System.get_env("CONSUMER_SECRET"),
        access_token: System.get_env("ACCESS_TOKEN"),
        access_token_secret: System.get_env("ACCESS_TOKEN_SECRET")
      )

      opts = [screen_name: "devoncestes", count: 200]

      Task.async(fn ->
        one_week_ago = DateTime.add(DateTime.utc_now(), -(60 * 60 * 24 * 7))

        opts
        |> ExTwitter.user_timeline()
        |> Enum.filter(&delete_tweet?(&1, one_week_ago))
        |> Enum.each(&ExTwitter.destroy_status(&1.id))
      end)

      Task.async(fn ->
        one_day_ago = DateTime.add(DateTime.utc_now(), -(60 * 60 * 24))

        opts
        |> ExTwitter.favorites()
        |> Enum.filter(&delete_tweet?(&1, one_day_ago))
        |> Enum.each(&ExTwitter.destroy_favorite(&1.id, []))
      end)
    end
  end

  defp delete_tweet?(tweet, date) do
    tweet.created_at
    |> Timex.parse!("{WDshort} {Mshort} {0D} {h24}:{m}:{s} {Z} {YYYY}")
    |> DateTime.diff(date)
    |> Kernel.<=(0)
  end
end
