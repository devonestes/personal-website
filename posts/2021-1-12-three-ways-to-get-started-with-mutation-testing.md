---
title: Three Ways To Get Started With Mutation Testing
tags: Elixir Mutation Testing Muzak
description: I've just pushed some significant functionality from Muzak Pro into Muzak, which means that it's even easier for folks to work some mutation testing into their workflow and start seeing the benefits! Today I'm going to break down three ways that you might want to get started with that.
date: 2021-1-12 01:01:01
---

I've just pushed some significant functionality from Muzak Pro into Muzak, which means that it's
even easier for folks to work some mutation testing into their workflow and start seeing the
benefits! Today I'm going to break down three ways that you might want to get started with that.
All three of these options are really easy to do, and each of them have different tradeoffs which
I'll go over so teams with different needs can get the most out of mutation testing.

## Test your most important files first

This is probably the most sensible option for many teams since it's really narrow in scope. We all
have those modules in our applications that have the *most important* behavior in them. Maybe this
is authorization logic to ensure data doesn't leak to unauthorized users, billing logic to make
sure your users are paying what they need to pay for your service, some complicated logic around
important third-party integrations, or something else really important. We definitely want to do
our best to ensure that regressions don't happen in these most important parts of the application,
and so we can use Muzak to run mutation testing on just these modules if we like. This option
gives us a nice balance between safety and runtime, since we're drastically reducing the number of
mutations that are generated and therefore reducing runtime.

To do something like this, we could create a new profile in our `.muzak.exs` file that looks
something like this:

```elixir
%{
  default: [
    # ...
  ],
  critical: [
    mutation_filter: fn _ ->
      [
        {"path/to/auth_logic.ex", nil},
        {"path/to/billing_logic.ex", nil},
        {"path/to/integration_logic.ex", nil}
      ]
    end,
    min_coverage: 98.0
  ]
}
```

That `mutation_filter/1` function that we define returns a list that basically says "make all
possible mutations on all lines of these three files," and the `min_coverage` setting says "exit
with a failure exit code if more than 2% of mutations aren't caught by our tests." You can then
run these mutation tests from the CLI manually (with `mix muzak --profile critical`) every now and
then to check up on what's maybe missing, and the minimum coverage level is set really, really
high so you're sure that you're covering the logic in these modules well. You could even combine
this idea with the next step to get continuous testing of these important modules if you wanted
to!

## Testing just the modified lines in CI

Probably the most common way of using mutation testing for teams is to use it as part of their CI
workflow. Of course running all mutations on every CI run is going to be rather wasteful, but with
the `mutation_filter` option we can restrict the mutations to only lines that have changed since a
previous `git` commit! That would look something like this:

```elixir
%{
  default: [
    # ...
  ],
  ci: [
    mutation_filter: fn _ ->
      split_pattern = ";;;"

      {commits_and_authors, 0} =
        System.cmd("git", [
          "log",
          "--pretty=format:%C(auto)%h#{split_pattern}%an",
          "--date-order",
          "-20"
        ])

      last_commit_by_a_different_author =
        commits_and_authors
        |> String.split("\n")
        |> Enum.map(&String.split(&1, split_pattern))
        |> Enum.reduce_while(nil, fn
          [_, author], nil -> {:cont, author}
          [_, author], author -> {:cont, author}
          [commit, _], _ -> {:halt, commit}
        end)

      {diff, 0} = System.cmd("git", ["diff", "-U0", last_commit_by_a_different_author])

      # All of this is to parse the git diff output to get the correct files and line numbers
      # that have changed in the given diff since the last commit by a different author.
      first = ~r|---\ (a/)?.*|
      second = ~r|\+\+\+\ (b\/)?(.*)|
      third = ~r|@@\ -[0-9]+(,[0-9]+)?\ \+([0-9]+)(,[0-9]+)?\ @@.*|
      fourth = ~r|^(\[[0-9;]+m)*([\ +-])|

      diff
      |> String.split("\n")
      |> Enum.reduce({nil, nil, %{}}, fn line, {current_file, current_line, acc} ->
        cond do
          String.match?(line, first) ->
            {current_file, current_line, acc}

          String.match?(line, second) ->
            current_file = second |> Regex.run(line) |> Enum.at(2)
            {current_file, nil, acc}

          String.match?(line, third) ->
            current_line = third |> Regex.run(line) |> Enum.at(2) |> String.to_integer()
            {current_file, current_line, acc}

          current_file == nil ->
            {current_file, current_line, acc}

          match?([_, _, "+"], Regex.run(fourth, line)) ->
            acc = Map.update(acc, current_file, [current_line], &[current_line | &1])
            {current_file, current_line + 1, acc}

          true ->
            {current_file, current_line, acc}
        end
      end)
      |> elem(2)
      |> Enum.reject(fn {file, _} -> String.starts_with?(file, "test/") end)
      |> Enum.filter(fn {file, _} -> String.ends_with?(file, ".ex") end)
    end,
    min_coverage: 85.0
  ]
}
```

I know that `mutation_filter/1` function is pretty gnarly, but what's happening there is we're
basically saying "only apply mutations to lines that have changed since the last commit by a
different author." You could change the logic in there depending on how your team works to do
something like "only apply mutations to lines that have changed since the last merge commit" or
something like that, but the above logic also works for teams that don't use merge commits in
their workflow, which is why I went with this as the example.

## Run everything!

Yes, mutation testing can take a while, but let's not forget that our computers are often sitting
idle! One totally valid way to get started with mutation testing is to just run the whole process
once, and then you'll have essentially a checklist of what can be improved and over time your team
can prioritize and chip away at that list. Maybe as you get to the end of your work day before a
long weekend you can kick off `mix muzak` and just let it run - there's no real harm in that!
Then, when you get back to work again it will likely be finished and you'll have some valuable
info that you can start working with.

Of course if you have a particularly slow test suite then this still might not work, and if
you have a particularly large application then you will likely hit the maximum mutation limit of
1000 that remains in Muzak, but as long as your test suite runs in under 220 seconds then you can
realistically run 1000 mutations over the course of a regular weekend, and a 275 second test suite
will probably finish 1000 mutations over the course of a 3-day weekend.

And of course if all of this isn't enough for you, then [Muzak Pro](https://devonestes.com/muzak)
has even more ways of making this process faster, as well as _many_ more mutators for a more
thorough test of your application's coverage!
