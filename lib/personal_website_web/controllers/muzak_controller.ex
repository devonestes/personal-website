defmodule PersonalWebsiteWeb.MuzakController do
  use PersonalWebsiteWeb, :controller

  def info(conn, _) do
    render(conn, "index.html")
  end

  def signup(conn, params) do
    {:ok, %{id: id}} =
      params["email"]
      |> get_args(params["password"])
      |> Stripe.Session.create()

    render_response(conn, id)
  end

  def get_credentials(conn, params) do
    url = create_git_user(params["session_id"])
    render(conn, "success.html", version: Mix.Project.config()[:version], url: url)
  end

  def manage(conn, %{"email" => email, "password" => password}) do
    {:ok, %{data: customers}} = Stripe.Customer.list(%{email: email})

    customers
    |> Enum.find(&(hd(&1.subscriptions.data).metadata["billing_portal_password"] == password))
    |> case do
      nil ->
        html(conn, "Looks like we couldn't find your account - go back and try again")

      customer ->
        {:ok, session} = Stripe.BillingPortal.Session.create(%{customer: customer.id})
        redirect(conn, external: session.url)
    end
  end

  def cancel(conn, _) do
    html(conn, "Cancel")
  end

  defp get_args(email, billing_portal_password) do
    {username, password} = PersonalWebsite.Muzak.gen_credentials()

    %{
      payment_method_types: ["card"],
      cancel_url: "https://www.devonestes.com/muzak",
      success_url: "https://www.devonestes.com/muzak/success?session_id={CHECKOUT_SESSION_ID}",
      customer_email: email,
      mode: "subscription",
      line_items: [
        %{
          quantity: 1,
          price: Application.get_env(:personal_website, :muzak_price_id)
        }
      ],
      metadata: %{
        username: username,
        password: password,
        billing_portal_password: billing_portal_password
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

    {:ok,
     %{
       metadata: %{"username" => username, "password" => password} = metadata,
       subscription: sub_id
     }} = Stripe.Session.retrieve(session_id)

    {:ok, _} = Stripe.Subscription.update(sub_id, %{metadata: metadata})

    :ok = PersonalWebsite.Muzak.create_user(username, password)
    "https://#{username}:#{password}@#{git_host}/muzak/muzak.git"
  end
end
