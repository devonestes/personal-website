---
title: Three Classes of Problems Found by Mutation Testing
tags: Elixir Mutation Testing
description: It's fairly common for folks who haven't used mutation testing previously to not immediately see the value in the practice. Mutation testing is, after all, still a fairly niche and under-used tool in the average software development team's toolbox. So today I'm going to show a few specific types of relatively common problems that mutation testing is great at finding for us (and that humans are notoriously bad at finding).
date: 2020-11-18 01:01:01
---

It's fairly common for folks who haven't used mutation testing before to not immediately see
the value in the practice. Mutation testing is, after all, still a fairly niche and under-used
tool in the average software development team's toolbox. So today I'm going to show a few specific
types of _very_ common problems that mutation testing is great at finding for us, and that
are hard or impossible to find with other methods. This is the code that we'll be working with
today:

```elixir
defmodule CoverExample do
  def write_json_to_file(map, path) do
    json = Jason.encode!(map)
    File.write(json, path)
    json
  end

  def stringify_keys(map) do
    map
    |> Enum.map(fn {k, v} ->
      if is_map(k) or is_tuple(k) do
        {inspect(k), v}
      else
        {to_string(k), v}
      end
    end)
    |> Map.new()
  end
end
```

And here are the tests that we've written for that code:

```elixir
defmodule CoverExampleTest do
  use ExUnit.Case

  describe "write_json_to_file/2" do
    @tag :tmp_dir
    test "gives us the correct JSON", context do
      map = %{"test" => "map"}
      assert CoverExample.write_json_to_file(map, context.tmp_dir) == Jason.encode!(map)
    end
  end

  describe "stringify_keys/1" do
    test "turns keys into strings" do
      map = %{
        1 => 2,
        :a => :b,
        [] => [],
        {} => {},
        "key" => "value"
      }

      expected = %{
        "1" => 2,
        "{}" => {}
      }

      stringified = CoverExample.stringify_keys(map)

      assert map_size(stringified) == 5
      assert expected = stringified
    end
  end
end
```

Here's what `cover` says about our tests:

![cover output](/images/cover_example.png)

We can see here that we have 100% code coverage, so we should be all good in terms of testing,
right? There's no way we could have any bugs here, and there's _definitely_ no way we can
reasonably break this code without causing a failing test.

**Just kidding!!** Neither of those two functions work at the moment, and we're not testing all of
the behavior in either of them despite "100% code coverage," so it's really easy to introduce a
regression without causing a failing test.

## The "multiple execution paths on a single line" problem

In our test for the `stringify_keys/1` function, and the `cover` output for that test, we can see
that we're testing both branches in the `if` statement in that function. But our test for that
function only passes a tuple as a key and never a map! So, if we were to change that code to be:

```elixir
if is_nil(k) or is_tuple(k) do
  {inspect(k), v}
else
  {to_string(k), v}
end
```

we wouldn't see a failing test. This could be correct behavior, or we could be introducing a bug
that might cause real problems for the users of our software - we just don't know, because that
behavior isn't tested anywhere! This is one of the huge ways in which "code coverage" that just
counts by lines of code executed in a test run falls short: it assumes that each line of code
contains a single execution path through the code in question, and that's **often** wrong.

Mutation testing, on the other hand, shows us if we're missing test cases based on the **logic**
in our code instead of based on the **lines** in our code. I think we can all agree that this is a
far better measure of code coverage for an application, right?

## The "untested side effect" problem

At first glance, the code in our `write_json_to_file/2` function might _seem_ correct, and it
certainly is doing _something_, but based on those variable names I don't think it's actually
doing what we want. If you run this test, you might see a strange file created on your filesystem:

```bash
$ cat '{"test":"map"}'
tmp/CoverExampleTest/test-write_json_to_file-2-gives-us-the-correct-JSON
```

Yep - the file path and the file contents are switched! And yet we have 100% code coverage and
no failing tests, so all the feedback we're getting is telling us that things are good. This is
because we have an **untested side effect** in that function. And the real kicker is, like 90% of
the really important and useful stuff that happens in most applications are **side effects**. If
we're not testing them, then we're running a really high likelihood of a regression in an
important part of our application.

## The "missing pin" problem

Those first two problems I'd say are the biggest things that mutation testing can find for you
that you _can't_ easily find through things like looking at code coverage based on LOC. This next
problem however, is much more rare (although I still see it at least a couple times a year) and
very Elixir specific, so I figured I'd include it here today.

Our test for `write_json_to_file/2` is currently passing even though we're probably not doing what
the developer wanted it to do. Why could that be?

We're missing a `^`! The `^` (called the "pin operator") is used to avoid re-binding a variable in
a pattern match, but it's _super_ easy to forget them in tests, or to use the match operator `=`
in place of the equality operator `==` in a test. In either of those cases, you'll end up with a
passing test where you shouldn't have one.

If we change `assert expected = stringified` to `assert ^expected = stringified` or
`assert expected == stringified` we'll see the failure that the developer who wrote that code
probably intended to show. Mutation testing can give us this feedback to at least let us know that
there's something that's still not quite right and might need some additional human intervention
to resolve.

## Use computers instead of humans

The most important thing to note here is that currently, without mutation testing, the only way
you'll get feedback about these issues is from a human giving it to you. Either you'll figure it
out yourself as you're working on the code, or maybe someone will pick it up in a PR review, or
you'll get a bug report from a QA tester or a user. But for most teams there's no automated way of
getting this feedback quickly and easily that will scale with a development team as it grows -
this is where mutation testing comes in!

Code coverage is yet another thing that roughly follows the
[Pareto Principle](https://en.wikipedia.org/wiki/Pareto_principle). Code coverage based on lines
of code executed gets you 80% of the way there and takes 20% of the effort. It's easy to do, and
it's pretty good! But for applications that need (or want) a higher level of coverage, they're
going to need something like mutation testing to give them that extra 20% that other tools and
techniques just can't offer.
