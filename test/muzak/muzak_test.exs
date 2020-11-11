defmodule PersonalWebsite.MuzakTest do
  use ExUnit.Case, async: false

  describe "create_user/0" do
    @tag :skip
    test "creates a user who can clone muzak" do
      on_exit(fn ->
        File.rm_rf!("test_muzak_clone")
      end)

      repo = "#{Application.get_env(:personal_website, :git_host)}/muzak/muzak.git"

      {username, password} = PersonalWebsite.Muzak.gen_credentials()
      assert PersonalWebsite.Muzak.create_user(username, password) == :ok

      url = "http://sslemlsie:#{password}@#{repo}"

      assert {"", 128} = System.cmd("git", ["clone", url, "test_muzak_clone"])

      url = "http://#{username}:#{password}@#{repo}"

      assert {"", 0} = System.cmd("git", ["clone", url, "test_muzak_clone"])
    end
  end
end
