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
    Application.put_env(:personal_website, :stripe_public_key, System.fetch_env!("STRIPE_PUBLIC_KEY"))
    Application.put_env(:stripity_stripe, :api_key, System.fetch_env!("STRIPE_SECRET_KEY"))

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

    send_jfk_email()

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

  defp send_jfk_email() do
    if Mix.env() == :prod and Date.day_of_week(Date.utc_today()) == 6 do
      Task.async(fn ->
        {jfk_html, ec_html} = get_jfk_html()

        base =
          Email.build()
          |> Email.add_to("devon.c.estes@gmail.com")
          |> Email.put_from("devon.c.estes@gmail.com")

        base
        |> Email.put_subject("JFKS weekly update")
        |> Email.put_html(jfk_html)
        |> Mail.send()

        base
        |> Email.put_subject("JFK EC weekly update")
        |> Email.put_html(ec_html)
        |> Mail.send()
      end)
    end
  end

  @jfk_url "https://jfks.de/about-jfks/archive/"
  @ec_url "https://vrigney.weebly.com/"
  defp get_jfk_html() do
    ec_html = get_html(@ec_url, &Function.identity/1)

    jfk_html =
      get_html(
        @jfk_url,
        &(&1 |> Floki.parse_document!() |> Floki.find("#content-blog") |> Floki.raw_html())
      )

    {jfk_html, ec_html}
  end

  defp get_html(url, parser) do
    case Tesla.get(url) do
      {:ok, %{body: body}} -> ~s(<p><a href="#{url}">To website</a></p>#{parser.(body)})
      _ -> "Error getting HTML"
    end
  end
end
