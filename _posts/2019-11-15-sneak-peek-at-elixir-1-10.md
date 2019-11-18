---
title: A Sneak Peek at Elixir 1.10
tags: Elixir 1.10
description: It's already the middle of November, and that means that before you know it, January will be here - and January means time for a new version of Elixir!
date: 2019-11-18 00:00:00
---

It's already the middle of November, and that means that before you know it,
January will be here - and January means time for a new version of Elixir! There
have been some really cool things going on in Elixir development over the last
few months, and today I'm going to go over some of my favorites that have landed
on `master` so far. You can always check out the full [Changelog on GitHub](https://github.com/elixir-lang/elixir/blob/master/CHANGELOG.md).

Before I dive in, if you want to use some of this stuff now, working off of
Elixir's `master` branch is generally a safe and easy thing to do - and it
really helps find bugs before they're released! I use `asdf` as my version
manager, and if you do, too, you can run `asdf install elixir master-otp-22` to
install the current master branch. If you want to install Elixir a specific
commit of Elixir, you can use `asdf local elixir ref:<commit reference>`. After
that, you're ready to go! Pretty easy, right?

## Changes to sorting in some Enum functions

Currently in Elixir 1.9 there is only one way to sort - lowest to highest. If
you want to reverse that, you can use `Enum.sort/2` to get the desired
behavior like this: `Enum.sort(list, &>=/2)` or `list |> Enum.sort() |> Enum.reverse()`.
But now, with 1.10, we have `Enum.sort/2` that we can use, and we'll be able to
sort in a reverse order really easily: `Enum.sort(list, :desc)`.

Also, sorting in 1.10 leverages the `compare/2` function that is built into the
definition of most struct modules to make sorting even easier for things like
dates (which was notoriously tricky before). Now, instead of having to do:
`Enum.sort(dates, &(Date.compare(&1, &2) != :gt))`, we can shorten that to
`Enum.sort(dates, Date)`. To change the order, we call `Enum.sort(dates, {Date, :desc})`.
That's so much simpler, right?!

These changes have been implemented in `Enum.sort_by/3` as well, so
`Enum.sort_by(list, &byte_size/1, &>=/2)` now becomes `Enum.sort_by(list,
&byte_size/1, :desc)` and `Enum.sort_by(users, &(user.birthday),
&(Date.compare(&1, &2) != :gt)` can now be written as `Enum.sort_by(users,
&(&1.birthday), Date)`.

This sorting flexibility also made it's way to `min`, `max`, `min_by` and
`max_by` functions as well, which now allow a sorting function to be given, so
`Enum.min/2`, `Enum.max/2`, `Enum.min_by/3` and `Enum.max_by/3` are all new
functions for us to use in 1.10.

I think these are _great_ changes for user ergonomics and comprehension, and am
really happy to see them coming in the next release.

## New calendar parsing functions

This is the first step towards some more funtionality around dates and times in
Elixir that is still being discussed. There is already the wonderful Timex
library, but now working with the native calendar in Elixir (`ISO`), integrating
custom calendars, and converting between these different calendar types should
all be much easier.

I know, this seems like such a weird edge case kind of thing ("who would ever
use a calendar other than ISO?"), but this sort of problem turns up way more
often than you would expect! For example, if you're planning on doing anything
involving dates or times in Japan, India, Israel, Taiwan or Thailand, you're
going to need support for other calendars. That's a _lot_ of potential users
that might be seeing bugs if you're using a different calendar than they do!

So, if you're in this boat, you can now implement the `parse_time/1`,
`parse_date/1`, `parse_naive_datetime/1` and `parse_utc_datetime/1` callbacks to
your calendar implementations to make parsing and conversion between calendars
much easier! This also makes using the sigils for dates and times and such much
easier since now those can be parsed using a different calendar like so:
`~D[20001-01-01 MyCustomCalendar]` to specify the calendar module that should
be parsing the given string.

So, while this might not affect most users today, it makes things a lot nicer
for billions of people around the world - both developers and users - when
they're interacting with Elixir or with software written in Elixir.

## Erlang logger integration

Since OTP 21, Erlang has had its own logger, but Elixir hasn't been using that -
until now! Starting with Elixir 1.10, Elixir will use Erlang's logger instead of
its own logger as the backend to the `Logger` module. This is possible because
Elixir 1.10 requires OTP 21.0 or greater, which means we know that Erlang's
`logger` will be available to us.

Why is this a big deal? Well, the most important thing (to me) is that it brings
the Elixir and Erlang codebases and communities closer together, which is always
nice. But also, Erlang's logger is going to have performance benefits because
the OTP team can heavily optimize the BEAM for the specifics of its logger. The
more we can rely on built-ins in Erlang, the more we're going to share in the
benefits of the optimizations that the OTP team is working on.

One other benefit is that we no longer have two loggers running at the same
time, which is probably happening right now. Currently, setting a log level
for the Elixir logger doesn't affect the Erlang logger, and vice-versa. With
Elixir 1.10, setting the log level in one place means that the level for _all_
your applications - Elixir & Erlang - will be changed. This is important because
we all have Erlang applications at the base of our Elixir apps (and if you think
you don't, go check again). Bringing these two parts of our applications closer
together will lead to better applications with fewer bugs and simpler
management.
