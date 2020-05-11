---
title: From Elixir to Erlang
tags: Elixir Erlang Ecto Phoenix
description: It's been a while since I've written here, partly because I've been taking care of my kids mostly solo for a while while my wife is out of town, but also because I've been working with a new client since the middle of April. 
date: 2019-6-12 00:18:00
---

It's been a while since I've written here, partly because I've been taking care
of my kids mostly solo for a while while my wife is out of town, but also
because I've been working with a new client since the middle of April. At this
client I've been writing Erlang full-time (when I'm not doing operations
stuff) for the first time, and I've recently been reflecting on a few things I
still find myself missing from Elixir, and a few things I thought I would miss
but surprisingly don't.

Just to be extra clear, when I say below that I "don't miss" something, that
doesn't mean I'm happy that it's gone. It just means that I thought that I would
really miss it, but I'm not really feeling that. For all of these things I'd be
totally happy to have them back!

Also, for some of these things that I do miss, I might just not yet know some
really good way to do this stuff in Erlang. If you have resources to share,
please do get in touch and let me know!

## I don't miss Elixir's syntax

Everyone complains about Erlang syntax, and I understand that Prolog style
syntax is rather unfamiliar for most people. But after a couple of days, you get
used to it. I'm as fast now reading and writing Erlang as I am with Elixir. I
know a lot of people are coming to Elixir instead of Erlang because it looks at
first glance like some other language they already know, but if you take a
little bit of time to get it into your fingers, Erlang syntax is just as fine as
any other language's syntax.

## I miss ExUnit

I always thought it was kind of weird that Erlang has two testing frameworks
built in (EUnit and Common Test), but I've gotten over that. I do miss a bunch
of the conveniences that are built into ExUnit, though! For example, the nice
colored diffs when comparing terms and the super helpful error messages in
ExUnit make TDD a nicer experience versus in EUnit or Common Test. Also, the SQL
Sandbox mode that allows me to write safe unit tests that hit a database is
something I miss a bunch. Which leads me to my next thing...

## I miss Ecto

Ecto is a truly wonderful query builder. The app I'm working on now has
basically a hand-rolled query builder, and it's much less flexible and much more
difficult to work with. It works, sure, but it doesn't make things as easy as
Ecto does - not by a long shot. I especially dislike having to manually manage
my connection pool and transactions in that library that's being used. Ecto does
such a great job of hiding tha stuff from me that I honestly forgot for a while
that it was something that Ecto did!

## I don't miss Phoenix

The project I was on before this one used a lot of streaming and websockets. I
can't imagine doing that in Erlang right now, but my current project doesn't
need any of that stuff. It's a pretty small service, actually, and so just using
Cowboy directly works just fine. Phoenix is a fine library, and I would totally
use it in Elixir 99.99% of the time, but for this simple service I haven't found
myself missing Phoenix at all, surprisingly.

## I miss really good Unicode support

The app I'm working on is more than 10 years old(!!!), and so it predates when
Erlang had really good Unicode support. In fact, it's still running on OTP 19.
Yes, at this point technically the Unicode support is much better than it was 10
years ago, but there's a lot of legacy stuff that dates from before the Unicode
days. And this app has users across pretty much all of Europe, so UTF-8 is a must
have. The fact that really good Unicode support isn't even something you need to
think about in Elixir is definitely something that I wasn't expecting to miss,
but have had multiple times when I've found myself saying "this would be so easy
in Elixir!" over the last two months.

## I don't miss mix

Mix is a great tool, but Rebar3 is great now, too! Sure, there are a couple
little features I miss in mix, but I've not found myself even once getting stuck
on something that mix would have solved for me. Plus, I'm getting back into
working with Makefiles again, which I think are really great and I'm happy to be
using. Maybe I'm weird, but I really love Makefiles and bash for automating
tasks.
