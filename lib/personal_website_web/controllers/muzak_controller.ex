defmodule PersonalWebsiteWeb.MuzakController do
  use PersonalWebsiteWeb, :controller

  def info(conn, _) do
    render(conn, "index.html")
  end

  def signup(conn, _) do
    {:ok, %{id: id}} = Stripe.Session.create(get_args())
    render_response(conn, id)
  end

  def get_credentials(conn, params) do
    url = create_git_user(params["session_id"])
    render(conn, "success.html", version: Mix.Project.config()[:version], url: url)
  end

  def manage(conn, %{"email" => email}) do
    {:ok, %{data: [customer]}} = Stripe.Customer.list(%{email: email})
    {:ok, session} = Stripe.BillingPortal.Session.create(%{customer: customer.id})
    redirect(conn, external: session.url)
  end

  def cancel(conn, _) do
    html(conn, "This is where we cancel")
  end

  defp get_args() do
    {username, password} = PersonalWebsite.Muzak.gen_credentials()

    %{
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
  end

  defp render_response(conn, id) do
    html(conn, """
    <!DOCTYPE html>
    <html>
      <head>
        <title>Checkout</title>
        <script src="https://js.stripe.com/v3/"></script>
      </head>
      <body>
        <script>
          Stripe("#{Application.get_env(:personal_website, :stripe_public_key)}")
            .redirectToCheckout({sessionId: "#{id}"})
            .then(handleResult);
        </script>
      </body>
    </html>
    """)
  end

  defp create_git_user(session_id) do
    git_host = Application.get_env(:personal_website, :git_host)

    {:ok, %{metadata: %{"username" => username, "password" => password}, subscription: sub_id}} =
      Stripe.Session.retrieve(session_id)

    update_params = %{metadata: %{username: username, password: password}}
    {:ok, _} = Stripe.Subscription.update(sub_id, update_params)

    :ok = PersonalWebsite.Muzak.create_user(username, password)
    "http://#{username}:#{password}@#{git_host}/muzak/muzak.git"
  end
end
