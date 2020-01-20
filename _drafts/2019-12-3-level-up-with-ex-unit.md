---
title: Leveling up your Elixir skills with ExUnit
tags: Reading Code ExUnit Elixir
description: It's December, so the holidays are coming up, and one of the things I like to do during the holiday break is take some time to do a little reading, exploring and learning.
date: 2019-12-3 00:00:00
---

It's December, so the holidays are coming up, and one of the things I like to do
during the holiday break is take some time to do a little reading, exploring and
learning. If you're thinking of doing the same thing, and you want to learn some
more about some of the more advanced or difficult features of Elixir, today I'm
going to recommend a couple pieces of code that will help you do just that!

ExUnit is one of my favorite applications in the Elixir ecosystem, not just
because I really like testing and I think ExUnit is a great testing library, but
because there's a lot of great stuff to learn from its implementation! Also,
it's really well tested, so if you ever have questions about how stuff should be
working, you can always see lots of great examples in the tests.

## Macros

At the core of ExUnit are the `assert` and `refute` macros. Macros can be really
tricky to understand, and for good reason, but these macros are surprisingly
simple! If you've never messed around with macros before, `ExUnit.Assertions` is
a great module to read and explore to learn more. There's also some slightly
more complicated macros in `ExUnit.Doctest`, so if you've read
`ExUnit.Assertions` and feel comfortable with that, `ExUnit.Doctest` would be a
nice next step towards learning more about macros.

## OTP

ExUnit's runner uses OTP (processes and supervisors) to do parallel test
execution, and it's a surprisingly simple and (in my opinion) easy to understand
OTP application. I'd start with looking at `ExUnit.Runner`,
`ExUnit.EventManager`, and `ExUnit.Server`, since those are the two primary
abstractions that ExUnit uses in the running of its tests. There's also some
really cool stuff to learn about OTP from the `ExUnit.CaptureIO` and
`ExUnit.CaptureServer` module.

