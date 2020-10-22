defmodule PersonalWebsiteWeb.MuzakController do
  use PersonalWebsiteWeb, :controller

  def info(conn, _) do
    html(conn, """
    <!DOCTYPE html>
    <html>
      <head>
      </head>
      <body>
        <a href="/muzak/subscribe">Subscribe now!</a>
        <form action="/muzak/manage" method="get">
          <label for="email">Email:</label><br>
          <input type="text" id="email" name="email"><br>
          <input type="submit" value="Submit">
        </form>
      </body>
    </html>

    """)
  end

  def signup(conn, _) do
    {username, password} = PersonalWebsite.Muzak.gen_credentials()

    args = %{
      payment_method_types: ["card"],
      cancel_url: "http://www.devonestes.com/muzak/cancel",
      success_url: "http://www.devonestes.com/muzak/success?session_id={CHECKOUT_SESSION_ID}",
      mode: "subscription",
      line_items: [
        %{
          quantity: 1,
          price: Application.get_env(:personal_website, :muzak_price_id)
        }
      ],
      metadata: %{
        username: username,
        password: password
      }
    }

    {:ok, %{id: id}} = Stripe.Session.create(args)
    stripe_public_key = Application.get_env(:personal_website, :stripe_public_key)

    html(conn, """
    <!DOCTYPE html>
    <html>
      <head>
        <title>Checkout</title>
        <script src="https://js.stripe.com/v3/"></script>
      </head>
      <body>
        <script>
          Stripe("#{stripe_public_key}")
            .redirectToCheckout({sessionId: "#{id}"})
            .then(handleResult);
        </script>
      </body>
    </html>
    """)
  end

  def get_credentials(conn, params) do
    git_host = Application.get_env(:personal_website, :git_host)
    version = Mix.Project.config()[:version]

    {:ok, %{metadata: %{"username" => username, "password" => password}, subscription: sub_id}} =
      Stripe.Session.retrieve(params["session_id"])

    update_params = %{metadata: %{username: username, password: password}}
    {:ok, _} = Stripe.Subscription.update(sub_id, update_params)

    :ok = PersonalWebsite.Muzak.create_user(username, password)
    url = "http://#{username}:#{password}@#{git_host}/muzak/muzak.git"

    html(conn, """
    <!DOCTYPE html>
    <html>
      <head>
      </head>
      <body>
        <h1>You've signed up!</h1>

        <p>You now have credentials to fetch `muzak` - you can add it to your deps like so:</p>

        <p>{:muzak, git: #{inspect(url)}, tag: #{inspect(version)}, only: :test}</p>
        <p>The above credentials are _only_ for your team, so please do not share them publicly. Since
          I optimized to make it easiest for folks to use, that means we're really working on the
          honor system here. I would really hate to have to make this more secure (and harder to use)
          if folks do the wrong thing 😀.</p>
      </body>
    </html>
    """)
  end

  def cancel(conn, _) do
    html(conn, "This is where we cancel")
  end

  def manage(conn, %{"email" => email}) do
    {:ok, %{data: [customer]}} = Stripe.Customer.list(%{email: email})
    {:ok, session} = Stripe.BillingPortal.Session.create(%{customer: customer.id})
    redirect(conn, external: session.url)
  end
end
