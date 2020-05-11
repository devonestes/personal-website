---
title: Adding Gleam to your Elixir project
tags: Elixir Gleam umbrella
description: There's a really cool new BEAM language out there called Gleam. It's super early days for the language, but what it offers (strong type safety) I think is worth some experimentation for folks that are interested.
date: 2019-10-23 00:18:00
---

There's a really cool new BEAM language out there called [Gleam](https://gleam.run/). It's super early
days for the language, but what it offers (strong type safety) I think is worth
some experimentation for folks that are interested. Lucky enough for those of us
currently using Elixir it's trivially easy to use Gleam code in your Elixir
applications. Today I'm going to show you how.

## Set up your umbrealla

Gleam compiles to Erlang and uses rebar3 as its build tool, and luckily Mix
knows how to work with rebar3 just fine. So what we're going to do is to set up
an umbrella application, where one application is a standard Mix app, and the
other one is a standard Gleam app. Start off with this to generate a new Phoenix
application that sets up an umbrella app for you.

```
mix phx.new --umbrella gleam_example
```

Now that we have our two applications - `:gleam_example` and
`:gleam_example_web`, we are going to delete that `apps/gleam_example` directory
and set it up from scratch again as a Gleam application.

## Getting Gleam working

First, you'll need to have Gleam and rebar3 installed, which you can easily do
with `asdf`. Then, to start a new Gleam application we have a familiar CLI to
work with:

```
gleam new gleam_example
```

This generates the standard structure of a new gleam application. You should now
be able to `cd` into that directory and run the tests with `rebar3 eunit`. Once
that's all working, you've got the basics all hooked up alredy! Yay!

## Connecting the dots

Now that we have our two applications, we need to update a few things. First
off, we need to tell Mix that our Gleam project needs to use rebar3 for
compilation, so we can go to `apps/gleam_example_web/mix.exs` and we'll go down
to the `deps` function. We're going to look for the declaration of the
dependency that looks like this `{:gleam_example, in_umbrella: true}` and we're
going to add one more configuration option at the end that gets this all set for
us: `{:gleam_example, in_umbrella: true, manager: :rebar3}`.

Now if we try and start our server, it'll work, but we'll still see a warning in
our terminal that looks like this:

```
warning: path "apps/gleam_example" is a directory but it has no mix.exs. Mix
won't consider this directory as part of your umbrella application. Please add
a "mix.exs" or set the ":apps" key in your umbrella configuration with all
relevant apps names as atoms
```

I don't like warnings, so let's fix this. What's happening here is Mix is saying
"I found this directory in your `/apps` folder, but it doesn't look like it's a
Mix project, so why are you telling me to compile it?!" So let's tell Mix
specifically what apps we want it to compile for us by going to the top level
`mix.exs` file. There we'll see configuration that looks like this:

```
  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end
```

Because we've set `apps_path: "apps"`, Mix assumes that all directories there
are Mix applications. We need to tell Mix that this is not true by explicitly
adding an `apps:` key to that configuration:

```
  def project do
    [
      apps_path: "apps",
      apps: [:gleam_example_web],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end
```

Now it will only try and compile the Elixir application for us and not the Gleam
application!

## The results

Now that we can start our server with `mix phx.server` and we don't get any
warnings, let's actually show something that's called in Gleam. We can go to our
PageController that's automatically generated for us and make the cannonical
Hello, world! example. Luckily, because Gleam compiles to Erlang, it looks
pretty familiar:

```
defmodule GleamExampleWeb.PageController do
  use GleamExampleWeb, :controller

  def index(conn, _params) do
    text(conn, :gleam_example.hello_world())
  end
end
```

And that's it! Now we have a Phoenix application that calls Gleam code!

The only thing that doesn't work super well right off the bat is running tests
for your entire umbrella app, and that's because Mix doesn't know how to run
tests for rebar3 projects when you run `mix test`. I kind of get that, and I'm
ok with it for now. If you want to have a single command that runs all your
tests, you can put something like this in a bash script or a Makefile: `mix test
&& (cd apps/gleam_example && rebar3 eunit)`.

If you want to check out the final results for this little example project, it's
[on GitHub](https://github.com/devonestes/gleam_example).
