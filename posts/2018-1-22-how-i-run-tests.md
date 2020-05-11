---
title: How I run tests 
tags: Elixir TDD Testing 
description: In recent weeks I've learned that it's not just writing tests that's important to me, but actually how I use them to benefit my development that matters as well. 
date: 2018-1-22 00:18:00
---

In recent weeks I've learned that it's not just writing tests that's important
to me, but actually how I use them to benefit my development that matters as
well. Maybe this is just the [Dunning-Kruger effect](https://en.wikipedia.org/wiki/Dunning%E2%80%93Kruger_effect)
talking, but I think the way I go about running my tests is really helpful, so I
figured I'd share what I do in certain situations. In this post I'm going to use
Elixir and ExUnit in the examples because that's what I've been working in
recently and what's actually led to this realization, but the ideas here aren't
exclusive to this language or testing library. They _should_ be applicable
elsewhere as well.

## When multiple tests are failing

Sometimes when I undergo some significant refactoring, like, for example
changing the data type of an input to a higher level function from a keyword
list to a struct or something. This will probably mean I need to update several
other tests to reflect this change, and until I go and update all those tests
and the corresponding code, those tests will be broken.

Seeing a lot of red in my console really bums me out. It's kind of overwhelming.
I really need to focus on one thing at a time. If I don't, I don't get anything
done. So, whenever I encounter this situation, I first go through and skip every
failing test. In Elixir I do this by adding `@tag :skip` and in RSpec I use
`xit`. I also make sure that I use code folding to my advantage and fold all the
tests I'm not currently working on so I only see the code relevant to the task
at hand. I then go test by test, **one at a time**, and I make that test and the
corresponding code correct.

And, while I'm doing that, I'm always running my full test suite. While
refactoring, I always want to make sure that my changes aren't accidentally
breaking something somewhere else. This is why I skip tests instead of running
single tests at a time with something like `mix test test/benchee_test.exs:23`.
This all ensures that I stay focused on one problem at a time, and that I'm not
accidentally making things worse by keeping my focus too narrow. If I find that
a change I made breaks a bunch of other stuff, I immediately undo that change
and go at it again in a different direction so I never have more than the one
test I'm working on at a time. Then, when I have my whole suite green again and
no more skipped tests, I can repeat this process if need be.

I also do this if I'm testing from the outside in. If I start with some sort of
higher level integration test, but then find that I want a unit test for some
associated function, I'll skip the integration test until the unit test is
passing. Until we learn how to fully merge with the computer so we can have
brains with multiple CPU cores, I can only do one thing at a time, so I do
whatever I can to keep that focus.

## When I need to see some sort of debugging output

I guess there's a theme here of me not liking to see too much output in my
terminal when I'm running tests. If I'm working on some problem and I need to
check in at the status of some variable somewhere and I'm printing that with
`IO.inspect/1` or something, that's the only time I run a single test instead of
the whole suite. Otherwise you can get so much noise in your terminal that
you're digging through lines and lines of output to try and find the actual info
you're looking for. If you're not used to doing this, it's a real life changer!

## When I'm doing TDD

I like TDD, but I don't do it 100% of the time. Maybe more like 80% of the time.
Some things are just super small and I know how to test that I'm solving the
problem in another way, so I do that first. Or maybe I never even add the test!
Sacrilege, I know. But, when I am doing TDD, I always have some sort of
automatic test runner going in the background. For Elixir I use [`exguard`](https://github.com/slashmili/ex_guard),
and for Ruby I use [`guard`](https://github.com/guard/guard). This lets me both
configure which tests are run on which kinds of changes to certain files, and
also makes sure that my tests are running on save of any watched file. I also
like to configure the alerts to use desktop notifications through something like
[`ex_unit_notifier`](https://github.com/navinpeiris/ex_unit_notifier) so I don't
even need to switch over to the other tab to see the results.

With an automatic test runner I can keep my focus on actually solving the
problem at hand, but also getting fast feedback that I'm not accidentally making
a mess of something else.

## When I have slow feature tests

Ok, so I know I've been speaking about always running the whole suite, but let's
be honest - that doesn't _always_ happen. I've worked on some Ruby codebases
where there are suites of feature tests that take minutes to run. Clearly I'm not
going to wait minutes in between every small change. So, I find some way to
separate the test suite into relevant pieces so if I'm working on a given unit
I also have a couple feature tests that are running as well. In Elixir I do this
by adding `@tag`s to those tests so I can run just those tests together. So, I
can do `mix test --only post_tests` and just run those tests I want.

But, then again, I've only run into this problem in Elixir once in the last two
years since tests in Elixir are generally really fast and the language and its
associated libraries also push you to better design of unit tests. In Ruby it's
a much more common problem. The maximum time I allow for this group of tests to
run is usually around 10 seconds. Anything more than that and it starts becoming
really annoying. Luckily RSpec also has a way of applying metadata to tests and
filtering by that metadata.
