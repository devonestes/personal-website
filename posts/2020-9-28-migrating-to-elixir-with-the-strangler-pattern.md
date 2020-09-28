---
title: Migrating to Elixir with the Strangler Pattern
tags: Elixir Migrating
description: I think it's fair to say that a good amount of folks - if not the majority of them - using Elixir in production today are doing so after migrating an application to Elixir from some other language instead of just building in Elixir from scratch. Of course this idea of re-writing an application is scary, and rightly so! But there are some ways to make this process simpler and less scary, and also to reduce the likelihood of introducing regressions during this process, and that's what I'm going to go over today.
date: 2020-9-28 00:18:00
---

I think it's fair to say that a good amount of folks - if not the majority of them - using Elixir
in production today are doing so after migrating an application to Elixir from some other language
instead of just building in Elixir from scratch. Of course this idea of re-writing an application
is scary, and rightly so! But there are some ways to make this process simpler and less scary, and
also to reduce the likelihood of introducing regressions during this process, and that's what I'm
going to go over today.

## The Strangler Pattern

Martin Fowler gives an explanation of a pattern he calls the [Strangler Fig Application on his Bliki](https://martinfowler.com/bliki/StranglerFigApplication.html),
and that's the idea that what we'll be starting with here. Basically this pattern involves
wrapping an existing application with some other application and gradually replacing pieces of
that old application over time. This allows for a team to slowly move over to the new application
while leaving the old application in place, and, more importantly, to test the replacement against
the original application to make sure things are working as expected.

Often this sort of migration is done one route at a time, so for each route in your router you'd
migrate one route at a time until they've all been migrated over. So, how does one implement this
in Elixir?

The first step is to start with an application that basically is just a router that forwards all
requests to the old application - that might look something like this:

```elixir
defmodule FigWeb.Router do
  use FigWeb, :router

  match(:*, "/*path", FigWeb.RedirectController, :forward)
end

defmodule FigWeb.RedirectController do
  use FigWeb, :controller

  def forward(conn, _) do
    redirect(conn, external: "https://path.to_your_old.application")
  end
end
```

With that in place, you've now got a seam in which you can work! Because routers just use pattern
matching on routes from top to bottom, you can easily start moving routes to your new application
one by one as you're working like so:

```elixir
defmodule FigWeb.Router do
  use FigWeb, :router

  get("/users", FigWeb.UserController, :get)

  match(:*, "/*path", FigWeb.RedirectController, :forward)
end
```

Now any request to `GET /users` will be handled by the new Elixir application instead of forwarded
on to the old application. But of course before we do this in production we'd love to get some
confidence that this new implementation matches the old application's implementation. So, we'll do
some testing!

## Testing the replacement

The thing about replacing behavior is that you don't always (realistically, never) know _everything_
that a given HTTP endpoint should do. That's where testing in production comes into play! Luckily,
the setup we have now allows us to do that easily. Building on the example above where we're now
going to start handling `GET /users` in our new application, that controller might start out
looking something like this:

```elixir
defmodule FigWeb.UserController do
  use FigWeb, :controller

  require Logger

  def get(conn, params) do
    spawn(fn ->
      new_impl = new_get(conn, params)
      old_impl = old_get(conn, params)
      log_error_if_different(new_impl_conn, old_impl)
    end)

    FigWeb.RedirectController.forward(conn, params)
  end

  defp new_get(conn, params) do
    # New implementation of this behavior here
  end

  defp old_get(conn, params) do
    # Make HTTP request to old service to get response
  end

  defp log_error_if_different(new_conn, old_resp) do
    # Check your new response against the old response to make sure they're the same
    # and log an error if they're different with a _ton_ of context so you can debug your new
    # implementation.
  end
end
```

What we're doing there is basically intercepting the request and spawning a new process that
makes that request against both our new and old applications (this is our test!) before continuing
on to redirect to the old application. If we find that anything doesn't match between the new and
old applications, we'll log a warning and all the details of the request so we can dig in and find
the bug in the new application.

If you run this in production for a few days (or weeks) without any differences between the two
applications, it's a fair bet to say you can - with 100% safety - move over to the new
implementation and remove the old implementation from the old application without breaking
anything.

Now of course this is much easier to do for `GET` requests than for `POST`, `PUT`/`PATCH` and
`DELETE` requests, but with a bit of planning and thinking, there are also ways you can use this
pattern to work on those endpoints, too. Also, if you want some idea about how these systems
behave before doing your testing in production, you can also run property based tests against
these endpoints. These can take a bit of time to set up properly if you have complicated behavior
in your APIs, but the same idea of running a single request against both systems and comparing
them for equality should hold true there as well. And those property based tests will provide you
with **tons** of value to protect against regressions well after the initial migration is
finished.

So that's the gist of how one might migrate a system over to Elixir! You can follow the process
laid out above, step by step, until eventually all the behavior in the old system has been
replaced by a new implementation in the new system. To sum it up, the steps are:

1. Put a router in front of your old application, starting with all requests routed to the old application,
2. Implement a replacement for a single route in the new application,
3. Send all traffic for that route to the new application, capturing the request for testing and then forwarding it to the old application,
4. When you're confident that the new implementation is correct, start using that and remove the redirect to the old application,
5. Repeat steps 2-4 until you've moved all traffic to the new application.

Of course this isn't a pattern that's exclusive to Elixir - it can be done to migrate any web
application from any system to any other system, but since I've seen a great number of teams doing
this kind of work, I felt it would be helpful to have an Elixir example out there for folks to
reference.

## P.S. - One note of caution!

It might be tempting to say something like "let's keep the old system around as an API for the new
system, that way we only need to migrate the behavior that changes." I completely understand the
thinking behind this. It makes sense - but only under the assumption that the old system is stable
and won't change much, and that's an assumption that I don't think has ever really held true in
software - at least for very long. Migrating things like HTML rendering and such can be annoying,
and you sometimes need to do a lot of work to just get your first route migrated over if there's a
lot of CSS involved. And so one might want to avoid that if possible, but migrations like this are
really best done in an "all or nothing" fashion.

A migration like this is one of those situations where you're adding some temporary complexity to
a system in the hopes of later simplifying it. This is a really common process for pretty much all
refactorings and changes to existing systems, but if you never actually _finish_ the work then
you're stuck with that added complexity that was intended to be temporary! You really want to aim
for an end state of your system that is as simple as possible, and to accept some temporary
complexity as a tool that helps you get to that end state. Stopping halfway through is just going
to take something that's probably already complex and making it more so - and that's not good!
