---
title: Testing Third Party Integrations
tags: Elixir Testing
description: One thing that is always hard, regardless of what language you're working in, is testing integrations with third party services. I mean, how are you going to test something like uploading files to S3 without actually uploading the file to S3?! The answer to that is usually "mocking," but then there comes the question of how exactly one does that. Well, today I'm going to show how I test these sorts of things in code I work on.
date: 2020-7-21 00:18:00
---

One thing that is always hard, regardless of what language you're working in, is testing
integrations with third party services. I mean, how are you going to test something like uploading
files to S3 without actually uploading the file to S3?! The answer to that is usually "mocking,"
but then there comes the question of how exactly one does that. Well, today I'm going to show
how I test these sorts of things in code I work on. But before we get to the actual mocking and
testing, there's one thing we need to do first!

## Wrap your dependencies

I'd say 99.99% of modern software uses open source dependencies to solve lots of problems for them.
The thing with dependencies, though, is that they change. You probably don't have any control over
them, and you might need to replace them, or make significant changes to how your application
integrates with these dependencies. And so, this is why I always recommend that folks "wrap" their
dependencies. What does this mean? Well, basically it means that instead of this:

```elixir
defmodule MyApp.Users do
  alias ExAws.{Config, S3}

  def save_avatar(to_bucket, to_path, file_path) do
    config = Config.new(:s3, Keyword.put(params, :json_codec, Jason))

    to_bucket
    |> S3.put_object(to_path, File.read!(file_path), opts)
    |> ExAws.request(config)
    |> case do
      {:ok, %{status_code: 200, body: _}} -> {:ok, to_path}
      error -> {:error, error}
    end
  end
end
```

where our application code is using our dependency directly, you would do this:

```elixir
defmodule MyApp.Aws.S3 do
  alias ExAws.{Config, S3}

  def put_object(to_bucket, to_path, local_file, opts \\ []) do
    to_bucket
    |> S3.put_object(to_path, File.read!(local_file), opts)
    |> ExAws.request(config())
    |> case do
      {:ok, %{status_code: 200, body: _}} -> {:ok, to_path}
      error -> {:error, error}
    end
  end

  def config(params \\ []) do
    Config.new(:s3, Keyword.put(params, :json_codec, Jason))
  end
end

defmodule MyApp.Users do
  alias MyApp.Aws.S3

  def save_avatar(to_bucket, to_path, file_path) do
    S3.put_object(to_bucket, to_path, file_path)
  end
end
```

Now we have one function that _we_ own, that wraps the behavior in the code that we _don't_ own.
This gives us two advantages:

* If we ever need to change the dependency that we're using, or if there are breaking API changes
    we need to deal with, we've got a single place to deal with that change as opposed to many
    places throughout our application, and
* It gives us a nice place to test things!

## Testing our wrapper

Right, so we've got this one function that handles the integration with our library, and that
library itself integrates with a third party service (in this case, AWS S3). So, how do we test
this `put_object/4` function? Well, we've got two levels at which we can do our mocking - at the
library level, or at the HTTP client level.

By this I mean that we can mock out something like `ExAws.request/2`, ensuring that the right
arguments are passed to that function. In theory, if `ExAws` is well tested and we trust that it's
working correctly, then we can be confident that our integration is going to work as long as we've
tested that we're passing the right arguments to that library. But I don't love this idea,
especially since there _is_ still another option.

I much prefer to mock at the HTTP client level in this case, because that allows us to be even
more confident, testing the functioning of the dependency all the way down to the HTTP client.
And, yes, we're still at this point assuming that the HTTP client works as intended and that given
the correct arguments it's going to do what we want. But, while still imperfect, it's a really
nice sweet spot between a good level of coverage and a reliable, reasonably easy test to set up
and reason about.

So, this is how I would test that function in our wrapper:

```elixir
# in config/text.exs
config :ex_aws,
  http_client: MyApp.ExAws.HttpClientMock

# in test/test_helper.exs
Mox.defmock(MyApp.ExAws.HttpClientMock, for: ExAws.Request.HttpClient)

# in tests/my_app/aws/s3_test.exs
defmodule MyApp.Aws.S3Test do
  use ExUnit.Case, async: true

  alias MyApp.ExAws.HttpClientMock

  describe "put_object/3" do
    test "makes the correct HTTP call to AWS" do
      Mox.expect(HttpClientMock, :request, fn method, url, body, headers, options ->
        content_length = byte_size(body)

        assert method == :put
        assert url == "https://s3.amazonaws.com/destination/file.jpg"
        assert options == []
        assert content_length > 0

        assert [
                {"Authorization", _},
                {"host", "s3.amazonaws.com"},
                {"x-amz-date", _},
                {"content-length", ^content_length},
                {"x-amz-content-sha256", _}
              ] = headers

        {:ok, %{status_code: 200, body: :ok}}
      end)

      assert {:ok, "file.jpg"} = S3.put_object("destination", "file.jpg", "local/file.jpg")

      Mox.verify!()
    end
  end
end
```

It's not perfect, but I think it's good, and this style of test has served me well throughout the
years. Of course, since this is the single place that we're integrating with this rather important
thing, we'll want to test it _really_ thoroughly here. Like, several tests for success cases, and
tests for every error case we can think of (within reason, of course).

## Testing our application

So now that we have a function that does what we want when we call it, and that includes
integrating with a third party service, what now? Well, we've got to make sure the rest of our
application that uses this functionality is also well tested. But, how do we test it? Do we test
just like above, or in some other way?

Well, you certainly _could_ test at the HTTP client level every time you're mocking out a call to
S3, but I personally don't do that. I'm of the mind that - since I own and wrote that wrapper and
the tests for it myself, and I've probably even seen it work in production - that it will be ok to
mock at that level instead of at the HTTP client level. What does this look like? Kind of like
this!

```elixir
defmodule MyApp.Users do
  alias MyApp.Aws.S3

  def save_avatar(to_bucket, to_path, file_path, s3_module \\ S3) do
    s3_module.put_object(to_bucket, to_path, file_path)
  end
end

defmodule MyApp.UsersTest do
  use ExUnit.Case, async: true

  alias MyApp.Users

  defmodule FakeS3 do
    def put_object(to_bucket, to_path, file_path) do
      send(self(), {:put_object, to_bucket, to_path, file_path})
    end
  end

  describe "save_avatar/4" do
    test "makes the right call to our s3_module" do
      assert {:ok, "file.jpg"} = Users.save_avatar("destination", "file.jpg", "local/file.jpg", FakeS3)
      assert_receive {:put_object, "destination", "file.jpg", "local/file.jpg"}
    end
  end
end
```

And that's pretty much it! This idea of passing in a module as an argument to a function is a
thing I'm a big fan of, and the other idea of using `send` to test side effects (in this case,
HTTP calls) is another thing I'm a big fan of. I use them both a lot, and it's a pattern that I
recommend to just about everybody.

So, that's it! Like all things that relate to third party dependency integration, you're really
going to be testing this stuff in production. These tests give us a pretty high level of
confidence that things are working well, but nothing beats actually seeing the code work in
production, so you'll always want to have some way of observing things in production for sure.
