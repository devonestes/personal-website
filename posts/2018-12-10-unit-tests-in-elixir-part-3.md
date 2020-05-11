---
title: Unit Tests in Elixir - Part 3
tags: Elixir ExUnit Testing Tests Unit
description: In part 1 of this series I went over a couple rules that I follow when writing unit tests, and in part 2 I showed how to unit test GenServers. Today, though, we're gonna be getting our hands dirty and breaking some of those rules that I laid out in part 1. I mean, what good are rules if you don't break them every now and then!
date: 2018-12-10 00:18:00
---

In [part 1](/unit-tests-in-elixir-part-1) of this series I went over a couple
rules that I follow when writing unit tests, and in
[part 2](/unit-tests-in-elixir-part-2) I showed how to unit test GenServers.
Today, though, we're gonna be getting our hands dirty and breaking some of those
rules that I laid out in part 1. I mean, what good are rules if you don't break
them every now and then!

In Part 1 I defined a unit test as "all behavior within a single function
and within a single process." Basically that boils down to the old adage of
"don't test side effects." In part 2 I showed how to unit test functions with
side effects by asserting that a message was sent to another process and not
making assertions on what actually happened in that process as a result of
sending that message.

But today, I'm going to show two examples of times where I _do_ test side
effects. Prepare yourselves for the horror to follow!

## Interacting with the database

If you think that you shouldn't test an application's interaction with the
database, you're not wrong. Testing the interaction between your software and
software that is often running on an entirely different server is an integration
test for sure.

However, if you have an application that interacts with a database, it probably
does it _a lot_. And those interactions are probably pretty important! So, given
that it's pretty hard in many cases to avoid interacting with the database, and
the importance of those interactions, it makes sense to test them if it's
convenient enough.

And boy, is it ever convenient! After the release of Ecto 2.0 it became so
effortlessly easy to test functions that interact with a database, it's just
frankly harder to write your unit tests in a way where you're mocking out your
database interactions. So, given that, why would you use a mock `Repo`? Let's
just use the real thing!

Just for reference, let's imagine that we have the following module and the
following test:

```
defmodule MyApp.Users do

  alias MyApp.{Repo, Users.User}

  def create(params) do
    User
    |> User.changeset(params)
    |> Repo.insert()
  end
end

defmodule MyApp.UsersTest do
  use ExUnit.Case, async: true

  alias MyApp.{Users, Users.User}

  describe "create/1" do
    test "creates a new user in the database" do
      params = %{name: "name"}
      Users.create(params)
      assert [%User{name: "name"}] = Users.all()
    end
  end
end
```

That's really clear and easy to understand what's going on. If we wanted to make
that a "real" unit test, we could do something like this:

```
defmodule MyApp.Users do

  alias MyApp.{Repo, Users.User}

  def create(params, repo \\ Repo) do
    User
    |> User.changeset(params)
    |> repo.insert()
  end
end

defmodule MyApp.UsersTest do
  use ExUnit.Case, async: true

  alias MyApp.{Users, Users.User}

  defmodule Repo do
    def insert(changeset) do
      send(self(), {:insert, changeset})
    end
  end

  describe "create/1" do
    test "creates a new user in the database" do
      params = %{name: "name"}
      Users.create(params, Repo)
      assert_receive {:insert, changeset}
      # and then here we can make assertions about what's in the changeset.
    end
  end
end
```

That's not _so_ bad, but I sure do prefer the first version! Mainly because
there I'm making assertions about data in the database (well, really the data
that's retrieved from the database) and not about the contents of a changeset.
Tying my tests to the implementation detail of changesets seems brittle, and
frankly it's just unnecessary because of the great tooling in Ecto.

## Interacting with the file system

This one is a little more controversial. The file system is global
mutable state. If your unit tests are running concurrently (as I said they
should be in part 1), you're going to have race conditions when reading from and
writing to the file system, right? Let's use the following example:

```
defmodule MyCSV do
  def persist(list) do
    csv = Enum.join(list, ",")

    "../../output/results.csv"
      |> Path.expand(__DIR__)
      |> File.write!(csv)
  end
end
```

There's no way we can unit test that function with `async: true` because we'd be
running into issues with race conditions on that `results.csv` file. But, much
in the same way every test that touches the database is entirely isolated from
any other test, we can ensure that each of these unit tests is isolated from all
of the others as well.

First, let's extract a constant in that function out as a default variable:

```
defmodule MyCSV do
  @default_path Path.expand("../../output/results.csv", __DIR__)
  def persist(list, path \\ @default_path) do
    csv = Enum.join(list, ",")
    File.write!(path, csv)
  end
end
```

Now we have the ability to pass in a path to that function. This means when
we're unit testing that function, we can give a unique path for each test which
will ensure that the file system for each test is isolated.

But how can we generate a unique path for each test? Well, there are a few ways,
but here's my favorite. I have a function that I use pretty often that generates
a unique path, and it looks like this:

```
def unique_path() do
  path =
    Path.join([
      System.tmp_dir(),
      "test",
      "#{abs(System.monotonic_time(:nanosecond))}"
    ])

  File.mkdir_p!(path)

  path
end
```

The way I guarantee the uniqueness of this path is with
`abs(System.monotonic_time(:nanosecond))`. There's no way two tests can execute this
function in the same nanosecond to cause this to return with the same value
twice. Because every system is different, sometimes that monotonic time is
represented as a negative integer, so I use `abs/1` to ensure we're always given
a positive integer. And since we can't write to a file in a folder that hasn't
been created, we need that `File.mkdir_p!` in there to make sure that unique
folder exists before we put stuff in it.

Now when I test that function, it looks something like this:

```
defmodule MyCSVTest do
  describe "persist/2" do
    test "converts the list to a CSV and writes it to the file system" do
      base_path = unique_path()
      path = File.join(unique_path, "results.csv")
      MyCSV.persist([1,2,3], path)
      assert File.read!(path) == "1,2,3"
      File.rm_rf!(base_path)
    end
  end
end
```

Now, to present the alternative, you could also unit test that function in a
different way. Instead of extracting the path, you could do this:

```
defmodule MyCSV do
  def persist(list, file_module \\ File) do
    csv = Enum.join(list, ",")

    "../../output/results.csv"
      |> Path.expand(__DIR__)
      |> file_module.write!(csv)
  end
end
```

And then in your test you could use a fake module in place of the `File` module
and assert that a command was sent in the same way we did in those assertions for
GenServers in part 2. However, if it's easy enough to avoid using a mock for a
module I tend to avoid it, and in this case I consider it really easy.

In general it's better to use mock data than to use mock functionality, and this
is a really good example of the difference between those two options.
