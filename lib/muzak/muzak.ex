defmodule PersonalWebsite.Muzak do
  @moduledoc """
  Context for dealing with Muzak-related operations, such as managing users.
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "http://#{Application.get_env(:personal_website, :git_host)}/api/v1"
  plug Tesla.Middleware.Headers, [{"accept", "application/json"}, {"content-type", "application/json"}]
  plug Tesla.Middleware.Query, [access_token: Application.get_env(:personal_website, :gitea_token)]
  plug Tesla.Middleware.JSON

  def gen_credentials() do
    {random_string(), String.capitalize("#{random_string()}_1")}
  end

  def create_user(username, password) do
    with :ok <- do_create_user(username, password) do
      add_user_to_team(username, password)
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

  defp add_user_to_team(username, password) do
    case put("/teams/2/members/#{username}", %{}) do
      {:ok, %{status: 204}} -> :ok
      _ -> :error
    end
  end

  defp random_string() do
    ?a..?z |> Stream.cycle() |> Enum.take(500) |> Enum.take_random(8) |> to_string()
  end
end
