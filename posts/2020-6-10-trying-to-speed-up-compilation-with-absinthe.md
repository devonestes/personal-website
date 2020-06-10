---
title: Trying To Speed Up Compilation With Absinthe
tags: Elixir Absinthe GraphQL Compilation
description: I run my tests a lot when I'm working, and nothing bums me out more when I'm running my tests so frequently is long compile times before I can even run my tests. One of the unfortunate issues with absinthe is that it's a very macro-heavy library, and as such it effectively touches every file in your application, meaning that you need to recompile a ton of files if you're using it.
date: 2020-6-10 00:18:00
---

I run my tests _a lot_ when I'm working, and nothing bums me out more when I'm running my tests so
frequently than long compile times before I can even run my tests. One of the unfortunate issues
with `absinthe` is that it's a very macro-heavy library, and as such it effectively touches
_every_ file in your application, meaning that you need to recompile a ton of files if you're
using it. Here's just one example from the application I'm currently working on:

```
touch lib/sketchql/users.ex && time mix compile
Compiling 81 files (.ex)
mix compile  27.73s user 6.21s system 313% cpu 10.810 total
```

Waiting 10 seconds to compile before I can run my tests after basically any change? No thank you!!

This is basically because of the way types are defined and then imported into the schema
definition, usually like this:

```elixir
defmodule BlogWeb.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom
  import_types BlogWeb.Schema.AccountTypes
  import_types BlogWeb.Schema.ContentTypes

  # ...
end
```

Because we're importing those in a macro, it means we've got a compilation dependency on those
files that define types. But then those files that define types are all referencing our resolvers
in macros like this:

```elixir
defmodule BlogWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  alias BlogWeb.Resolvers

  @desc "A user of the blog"
  object :user do
    field :id, :id
    field :name, :string
    field :contacts, list_of(:contact)
    field :posts, list_of(:post) do
      arg :date, :date
      resolve &Resolvers.Content.list_posts/3
    end
  end

  # ...
end
```

This then means that we've now got compilation dependencies on our resolvers, which basically
end up frequently touching most files in the application, even if not a compilation dependency
than as a remote call dependency. If only there was a way to get that schema to not have to
re-compile on every change...

Well, there is! I don't personally love it as a solution at the moment, but it's the best I've
come up with to solve this problem.

Normally when folks ask me about umbrella apps I tell them that they're not worth it unless you
have some very specific constraints around deployment. However, in this case, they can really help
with breaking this compilation problem up a bit. As our starting point, I'm using the
[Absinthe tutorial project](https://github.com/absinthe-graphql/absinthe_tutorial) as the example
application for this experiment.

The starting point I was at for the experiment was this:

```
$ touch lib/blog/content/content.ex && mix compile --verbose
Compiling 5 files (.ex)
Compiled lib/blog/content/content.ex
Compiled lib/blog_web/schema.ex
Compiled lib/blog_web/views/error_view.ex
Compiled lib/blog_web/router.ex
Compiled lib/blog_web/endpoint.ex
```

We can clearly see that the main issue is that we end up having to compile
`lib/blog_web/schema.ex`, which then means we need to recompile the router and endpoint, too. So,
we need to get `lib/blog_web/schema.ex` to stop being compiled - how might we do that? We've
pretty much got two options:

1) Stop using macros to import type definitions, or
2) Pull that out to a separate OTP application.

Since option 1 would require removing a huge chunk of macros from `absinthe` (and that's not
reasonably going to happen), we're left with option 2. I took a swing at this just to prove it,
and it does indeed work!

```
$ touch apps/blog/lib/blog/content/content.ex && mix compile --verbose
==> blog
Compiling 1 file (.ex)
Compiled lib/blog/content/content.ex
```

The example code is up [here](https://github.com/devonestes/absinthe_tutorial_umbrella) on GitHub.
I haven't tried to make this "good," and clearly this way of separating files isn't such a great
one,  but it does show that this can fix this compilation problem. From here, though, we've got a
new question of tradeoffs. 

* Is this going to introduce new problems or annoyances?
* Are there compilation time guarantees that `absinthe` gives us that we now lose?
* Is the complexity of an umbrella app worth the benefit to incremental compilation times?
* Is there actually some other, better solution to this problem that I haven't found yet?

Personally, I don't really have answers to these questions yet, but this is something that I'm
going to continue to look into to see if I can eventually find a nice way of making incremental
compilations faster while also keeping as much as possible of the benefits we get from a normal
OTP app.

And of course if anybody comes up with some better way of solving this problem, I'd love to hear
it!
