---
title: Designing For Elixir Compiler Hints
tags: Elixir 1.11 Compiler Design
description: There are some nice new features coming in Elixir 1.11, and one many folks are excited about are some new compile-time checks. The one I've heard the most excitment about is the the compile-time check for non-existent fields in structs.
date: 2020-9-7 00:18:00
---

There are some nice new features coming in Elixir 1.11, and one many folks are excited about are
some new compile-time checks. The one I've heard the most excitment about is the the compile-time
check for non-existent fields in structs. Basically, if you wrote this code today you wouldn't see
any warning at compile-time and instead get a runtime error for a missing key:

```elixir
date = DateTime.utc_now()
date.secnd
```

Of course finding typos is a good and noble effort, but to get the new compiler warnings you'll
need to write the code above in a somewhat strange way:

```elixir
date = %DateTime{} = DateTime.utc_now()
date.secnd
```

In 1.11, if you don't explictly tell the Elixir compiler what struct a given variable is supposed
to be at any given time, it won't know how to check that struct for missing keys. Also, this
explicit struct declaration is only local to a given function definition, so on Elixir 1.11 the
following will not emit a warning:

```elixir
defmodule Warnings do
  def fun_1() do
    date = %DateTime{} = DateTime.utc_now()
    fun_2(date)
  end

  defp fun_2(date) do
    date.secnd
  end
end
```

but this will:

```elixir
defmodule Warnings do
  def fun_1() do
    date = DateTime.utc_now()
    fun_2(date)
  end

  defp fun_2(%DateTime{} = date) do
    date.secnd
  end
end
```

The good news is, based on this line in the changelog for 1.11, I have a feeling this tracking of
struct references to variables in the compiler might one day be expanded further to require less
explicit declaration of struct types:

> While some of those warnings could be automatically fixed by the compiler, future versions will
> also perform those checks across functions and potentially across modules, where automatic fixes
> wouldn't be desired (nor possible).

The kicker that I see, though, we've been able to get compile-time warnings from incorrect field
access in structs in Elixir for quite some time already if you access fields in structs using
pattern matching, like so:

```
%DateTime{secnd: second} = DateTime.utc_now()
second
```

So based on this alone I'm already not really loving the power of this new feature. Especially
since Dialyzer would have caught all of these issues the whole time, with every version of the
code that's already been shown, as would the simplest of test. Given, the error message from
Dialyzer isn't great, but if you wanted to avoid shipping bugs to production, Dialyzer would have
found it for you.

**But then there's the problem of polymorphism.**

Lots of times, functions can work with many different types of data! For our short example,
let's stick with dates. How would we design our functions if we need this sort of this?

```elixir
defmodule Warnings do
  def seconds() do
    naive_date = NaiveDateTime.utc_now()
    date = DateTime.utc_now()
    {second_from(naive_date), second_from(date)}
  end

  def second_from(_) do
    # ...
  end
end
```

If we're really set on getting those compiler warnings, we've now got two options:
1. Write a function head for each possible struct type, or
2. Convert all of this polymorphic data into a single type of struct before passing to the
   function.

Option 1 is fairly simple, but I don't really love it as it introduces a lot of duplication.
Basically, I see a high cost with a low benefit:

```elixir
defmodule Warnings do
  def seconds() do
    naive_date = NaiveDateTime.utc_now()
    date = DateTime.utc_now()
    {second_from(naive_date), second_from(date)}
  end

  def seconds_from(%NaiveDateTime{} = date_time) do
    date_time.secnd
  end

  def seconds_from(%DateTime{} = date_time) do
    date_time.secnd
  end
end
```

Option 2 for our current case isn't so bad, since you could convert a DateTime to a NaiveDateTime
rather easily:

```elixir
defmodule Warnings do
  def seconds() do
    naive_date = NaiveDateTime.utc_now()
    date = DateTime.utc_now() |> DateTime.to_naive()
    {second_from(naive_date), second_from(date)}
  end

  def seconds_from(%NaiveDateTime{} = date_time) do
    date_time.secnd
  end
end
```

But in a larger application things get murkier. In your domain, do you really want to be creating
structs for each level of abstraction in your application for some protection against typos? This
feels to me like you need to jump through a lot of hoops to get a pretty small benefit. In all of
these cases Dialyzer still gives you all the same benefit with basically none of the cost.

There are already some specific things that I'm worried I'm going to start seeing in applications
as a result of this.

I hope we don't start seeing structs representing all the possible parameters for a given HTTP
endpoint, like this:

```elixir
defmodule UserController do
  defmodule CreateParams do
    defstruct :name, :age, :address
  end

  def create(conn, params) do
    params = %CreateParams{} = struct(CreateParams, atomize_keys(params))
    # ...
  end

  defp atomize_keys(params) do
    # Turn all string keys into atom keys
  end
end
```

This adds so much complexity for such a small benefit, and even after you've done this you're
still probably going to be validating your user input so you can return them helpful errors
if they've given you invalid data!

I also hope we don't start seeing things like this contrived example to change the owner of a blog
post or comment on a post, which deals with the polymorhpism issue I raised above:

```elixir
defmodule Post do
  defstruct :body, :user, :title, :created_at, :updated_at
end

defmodule Comment do
  defstruct :body, :user, :post, :created_at, :updated_at
end

defmodule Creatable do
  defstruct :user, :created_at, :updated_at
end

defmodule Posts do
  def change_owner(%Creatable{} = creatable, %User{} = new_user) do
    save_to_db(%Creatable{creatable | user: new_user})
  end

  def change_owner(post_or_comment, new_user) do
    Creatable
    |> struct(Map.from_struct(post_or_comment))
    |> change_owner(new_user)
  end
end
```

Look, if one day these compiler checks can replace Dialyzer (with better error messages), then
that's great! But that day isn't today, and I'm really quite worried that we're going to see a
bunch of folks doing stuff like this in the name of "safety." Right now the costs are too high and
the benefits are too low. If you _really_ want some of this stuff, use more pattern matching.

But, please, don't start desinging your applications to meet the current capabilities of
your tools! Design your applications as simply as possible and then leverage the tools available
to you to get whatever benefit out of them that you can. The tools will continue to evolve, and so
if you design to meet the tooling where it is, then you'll end up having to make tons of changes
as those tools change.

If you find that typos in struct fields is _really_ causing problems for your team, then sure, go
nuts using this to help. But I can't really imagine that being enough of a problem to justify the
cost of duplication or increased complexity that one would need to really use this new feature.
