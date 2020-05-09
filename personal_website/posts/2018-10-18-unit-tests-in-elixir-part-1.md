---
title: Unit Tests in Elixir - Part 1
tags: Elixir ExUnit Testing Tests Unit
description: Unit tests are important. So are end-to-end tests that mimic real user behavior. All the other stuff in between on the testing pyramid - not so much.
date: 2018-10-18 00:18:00
---

Unit tests are important. So are end-to-end tests that mimic real user behavior.
All the other stuff in between on the testing pyramid - not so much.

That's basically my philosophy behind testing. But defining what a unit test
even is can be really tricky! I mean, what if that function you're testing calls
a bunch of other functions? Is that function by definition a sort of
integration test?

Today I'm going to try and lay down some of the basic things I believe about
testing in Elixir. Later on I'll go over some of the finer points of how to do
unit tests for certain tricky things (like unit testing GenServers, unit
testing functions that send messages, unit testing functions that touch the file
system, unit testing functions that make HTTP calls, etc.).

I don't want to say these are rules, but I consider them solid guidelines that I
follow all the time when I'm writing unit tests.

### 1) All unit tests should run in parallel

If a test relies on some shared state, it isn't a unit test. There are many ways
that you can design your tests (and your code) to make this possible, and I'll
go over them in depth in future posts. But in general, each unit test should be
run within its own world and that means it's totally fine to run them in
parallel.

### 2) Unit tests cover all behavior in a single function within a single process

This is related to number 1, since if your unit test relies on changes happening
outside of a single process it can't be a unit test. At that point you're
testing integration between two processes which are always doing things
asynchronously. This is an integration test by default.

But if your function calls other functions, that's ok! As long as all the stuff
you're testing for is within a single process, it's still a unit test in my
book. Take the following example:

{% highlight elixir %}
defmodule MyApp.Transform do
  def validate_parse_and_format_for_csv(raw_json) do
    raw_json
    |> MyApp.Validation.validate_raw()
    |> MyApp.Parse.parse_validated()
    |> MyApp.Format.csv()
  end
end
{% endhighlight %}

Here we have a function that we're unit testing. The behavior of this function
is a composition of behavior of other functions. In theory, it should be
enough to simply test that those other functions are called with the right data
and then let the unit tests of those functions cover the rest for us, but I
don't like this approach in Elixir for many reasons (and I'm not going to go
into that today).

If I were to unit test that function, I'd test it in the following way:

{% highlight elixir %}
defmodule MyApp.TransformTest do
  use ExUnit.Case, async: true

  describe "validate_parse_and_format_for_csv/1" do
    test "returns a CSV formatted string when the json is valid" do
    end

    test "returns an error tuple when the given json is invalid" do
    end
  end
end
{% endhighlight %}

Yes, technically this test is duplicating tests that are already unit tested in
those composite functions, but when we're writing unit tests we're defining
behavior that we want from a function, **not** defining interactions between
objects (with a couple of exceptions, which I'll go into on another day). It's
just different in FP vs. OO, and it took me a little while to fully come to
terms with that.

### 3) Don't test library code

If you're using a library, you don't need to test what that library does for
you. For example, let's look at Ecto. You don't need to test the mere existance
of an association, or that the association works as expected. If you're using a
library, you need to trust that it works as documented - and it **is**
documented, right? Otherwise, you shouldn't be using that library.

### 4) One `describe` block tests one function

In ExUnit, you're only allowed one level of nesting with `describe` blocks. This
is by design! When you're writing unit tests, you should do it like this:

{% highlight elixir %}
defmodule MyApp.UsersTest do
  use MyApp.DataCase, async: true

  describe "find_with_posts/1" do
    test "finds a user and preloads their posts" do
    end

    test "returns nil if no user is found" do
    end
  end

  describe "find_with_comments/1" do
    test "finds a user and preloads their comments" do
    end

    test "returns nil if no user is found" do
    end
  end
end
{% endhighlight %}

Always put a describe block showing exactly which function is under test - even
if there's only one test for now! It makes reading tests much easier, especially
for those of us who like to use tests as documentation.

### 5) Use `setup` blocks sparingly

`setup` blocks can be helpful when you have a bunch of stuff that's used within
a bunch of tests. One especially great example of this is having the `socket`
set for you when you're testing Absinthe subscriptions. But using them too much
makes individual tests difficult to read. Only use them when you're able to
extract many lines of code (like, at least 5) from multiple tests (like, at
least 3). If you have simple things that are shared between tests, pulling those
things out to a module attribute is even easier and should be a first step
before a `setup` block.
