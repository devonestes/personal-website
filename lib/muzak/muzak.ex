defmodule PersonalWebsite.Muzak do
  @moduledoc """
  Context for dealing with Muzak-related operations, such as managing users.
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://#{Application.get_env(:personal_website, :git_host)}/api/v1"
  plug Tesla.Middleware.Headers, [{"accept", "application/json"}, {"content-type", "application/json"}]
  plug Tesla.Middleware.Query, [access_token: Application.get_env(:personal_website, :gitea_token)]
  plug Tesla.Middleware.JSON

  def gen_credentials() do
    {random_string(), random_password()}
  end

  def create_user(username, password) do
    with :ok <- do_create_user(username, password) do
      add_user_to_team(username)
    end
  end

  defp do_create_user(username, password) do
    body = %{
      email: "#{random_string()}@example.com",
      must_change_password: false,
      send_notify: false,
      password: password,
      username: username
    }

    case post("/admin/users", body) do
      {:ok, %{status: 201}} -> :ok
      _ -> :error
    end
  end

  defp add_user_to_team(username) do
    case put("/teams/2/members/#{username}", %{}) do
      {:ok, %{status: 204}} -> :ok
      _ -> :error
    end
  end

  @lowercase ?a..?z |> Stream.cycle() |> Enum.take(500)
  @uppercase ?A..?Z |> Stream.cycle() |> Enum.take(500)

  defp random_string(), do: @lowercase |> Enum.take_random(8) |> to_string()

  defp random_password() do
    lowercase = Enum.take_random(@lowercase, 4)
    uppercase = Enum.take_random(@uppercase, 4)
    integers = Enum.take_random(?0..?9, 3)
    special = Enum.take_random([?_, ?-, ?., ?}, ?{, ?[, ?]], 3)
    (lowercase ++ uppercase ++ special ++ integers) |> Enum.shuffle() |> to_string()
  end
end
