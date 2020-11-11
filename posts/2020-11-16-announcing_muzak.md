---
title: Announcing Muzak and Muzak Pro
tags: Elixir Mutation Testing
description: As of today, Muzak and Muzak Pro are live! If you follow me on twitter you may have seen some hints that I've been making some good progress recently on the mutation testing library that I've been working on for close to a year now, and I think things are in a good enough place to push up the first versions of both Muzak and Muzak Pro.
date: 2020-11-16 01:01:01
---

As of today, Muzak and Muzak Pro are live! If you follow me
[on twitter](https://twitter.com/devoncestes) you may have seen some hints that I've been
making some good progress recently on the mutation testing library that I've been working on for
close to a year now, and I think things are in a good enough place to push up the first versions
of both Muzak and Muzak Pro.

So now that that's out of the way, let's answer some questions folks may have.

## What is mutation testing?

Mutation testing is the process of programmatically introducing bugs to an application by
mutating the application's source code and then running that application's test suite.

Mutation testing is usually used for:

1. Identifying untested code paths
2. Identifying unused code paths
3. Identifying tests that never fail
4. Identifying tests that always fail together (duplicate coverage)
5. Identifying tests that run slowly and rarely fail (what some consider "low value" tests)

I've covered more about what this is in detail, including a quick example, in the
[documentation for Muzak](https://hexdocs.pm/muzak/what_is_mutation_testing.html), too. There are
good mutation testing tools available for several other languages, and I felt that it was
important for Elixir to have one as well.

## What is Muzak?

Muzak is the mutation testing library that I've written for Elixir applications. It is
[open source](https://github.com/devonestes/muzak) under the GPLv3 license, and available on
[Hex.pm](https://hex.pm/packages/muzak). It should work well for any Elixir application out there,
but it is relatively restricted in what mutations are available and how you can use it - for
example, it wouldn't be good to use in CI since it's limited to generating 25 random mutations
in each run. Even with those restrictions, I still think it will be a great starting point for
those looking to try out mutation testing for themselves to see how it works and what it can do.

Information on getting started with Muzak can be found in
[its documentation](https://hexdocs.pm/muzak/muzak.html#getting-started).

## What is Muzak Pro?

Muzak Pro is the full-featured, paid version of Muzak that is distributed via a private `git`
server and licensed under a commercial license. It
[costs $29/month](https://devonestes.com/muzak), and you can cancel your subscription at any time.
If you end up unsatisfied with Muzak Pro for any reason, you can
[email me](mailto:devon.c.estes@gmail.com) and I'll happily give you a full refund.

All billing and subscription management is done through hosted Stripe integrations - I don't even
have my own DB for this! - so there shouldn't be any concern about storage of your personal or
financial data.

Muzak Pro has a ton of features that aren't in Muzak (_yet_). There is a list of current and
upcoming features in Muzak Pro in the
[documentation for Muzak](https://hexdocs.pm/muzak/muzak.html#muzak-pro), but in general Muzak Pro
is designed for business use - for example, it has helpful features for making it useful as part
of a CI pipeline and for developers to use on the command line as they're working on new features
or bug fixes.

There are still quite a few features that I'm going to add to Muzak Pro that will help users find
additional ways to improve their test suites and codebases, and to make mutation testing
_even faster_, but I feel like what I have now provides enough value to any company currently
using Elixir to justify the cost of a Muzak Pro subscription.

## Can I get a free Muzak Pro subscription for my OSS project or non-profit company?

Probably! [Email me](mailto:devon.c.estes@gmail.com) and we can try and figure something out.

## Is this your job now?

No, nor do I want it to be. I'm approaching this as an extension of my open source work, not as a
job, and I don't currently see any way for this to become something that would create enough
income to be my full-time job. The distribution of Muzak Pro as paid software is mostly just a way
to ensure that this project lives on and is well maintained well into the future.

I didn't want to spend my time making a library that was just okay and didn't work well for
everybody - that's just a waste of time - but I also didn't want to commit to spending a huge
chunk of my free time working on making this library great without there being some way for me
to be compensated for that time. Basically, if I was going to do this I wanted to do it **really
well**, and I feel strongly that this will be a valuable addition to the Elixir community,
especially in helping businesses feel comfortable adopting Elixir, so I really wanted to do it.
But the only way I could justify undertaking this challenge was with some sort of funding.

After researching some different models for monetizing open source, I settled on the "open core"
model since I'm generally more comfortable with the "pay me for software that I've written"
thinking than I am with the "I've written some free software that you use and depend on, so
please sponsor me" thinking.

As support for Muzak grows I definitely plan on porting some features from Muzak Pro to Muzak,
but a mutation testing library is a hard thing to write, and a **very hard** thing to maintain
because you end up relying on a lot of private APIs to make it work really well, and these
private APIs can break without warning at any moment, making this a difficult job.
