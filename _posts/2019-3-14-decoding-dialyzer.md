---
title: Decoding Dialyzer - Part 1
tags: Elixir Dialyzer
description: Dialyzer can be a tricky tool to figure out, but it can also be really helpful in spotting bugs or inaccurate typespecs for us, so I'm going to go through a couple of the more common warnings that you'll see in your daily use of Dialyzer to help understand what's happening, some of the causes of those common warnings, and how you can resolve them.
date: 2019-3-14 00:18:00
---

Dialyzer can be a tricky tool to figure out, but it can also be really helpful
in spotting bugs or inaccurate typespecs for us, so I'm going to go through a
couple of the more common warnings that you'll see in your daily use of Dialyzer
to help understand what's happening, some of the causes of those common
warnings, and how you can resolve them.

For this series I'll be using `dialyxir` 1.0.0-rc4, and I'm going to show both
the new Elixir formatted warnings and the old Erlang formatted warnings for
these cases. If you're not using `dialyxir` 1.0.0 yet, I highly recommend it!
The formatting of warnings is **much** more helpful than the original
formatting.

Here's the code that we're going to be using for the examples today:

{% highlight elixir %}
defmodule Test
  @spec concat(atom(), String.t()) :: String.t()
  def concat(first, second) do
    Atom.to_string(first) <> second
  end

  @spec call_concat() :: String.t()
  def call_concat() do
    concat("string", :atom)
  end
end
{% endhighlight %}

That small bit of code has one fairly obvious bug, but because of that bug
Dialyzer gives us two warnings, and these two are among the more common (and
important!) warnings you'll see. One bug causing multiple warnings in Dialyzer
is a fairly common situation, by the way, so when you're looking at your
Dialyzer output, trying to group things together can often give you much more
information about how to resolve those warnings than trying to tackle one
warning at a time.

Let's start with arguably the most important - but also most confusing -
warnings: `no_return`.

## no_return

When we run Dialyzer on that very small program, one of the warnings we see
looks like this with the new formatting:

{% highlight plain %}
lib/my_app/test.ex:8:no_return
Function call_concat/0 has no local return.
{% endhighlight %}

or like this with the old Dialyzer formatting:

{% highlight plain %}
lib/my_app/test.ex:8: Function call_concat/0 has no local return
{% endhighlight %}

This warning is telling us that the function `call_concat/0` does not return.
Basically, there is no way that you can call this function and have it do
anything other than raise an exception.

This usually happens in two situations:

1) We're always raising an exception on purpose
2) We're always raising an exception even though we don't intend to

If your function is intentionally raising an exception every time it's called,
you can resolve this warning by explicitly annotating that in the spec for that
function like so: `@spec call_concat() :: no_return()`.

But it's that second case where Dialyzer is most helpful here. It's screaming at
us and saying "You have a serious bug here!" 

It's important to note here that Dialyzer can only tell us that we definitely
have a bug here because it knows for a _fact_ what the values of the variables
in that example are because we have a string and atom literal. For example, if
we have this code:

{% highlight elixir %}
defmodule Test do
  @spec concat(atom(), String.t()) :: String.t()
  def concat(first, second) do
    Atom.to_string(first) <> second
  end

  @spec call_concat(String.t(), atom()) :: String.t()
  def call_concat(string, atom) do
    concat(string, atom)
  end
end
{% endhighlight %}

Then Dialyzer won't give us a `no_return` warning. It gives us a different
warning, but it can't say for certain that there's a function that will not
return because an exception was raised. Only if `call_concat/2` were called
somewhere with something that Dialyzer can determine the type of with 100%
confidence (usually a literal) will it give us the `no_return` warning.

So, Dialyzer says we have a bug, but unfortunately it's not really telling us
_where_ that bug is in this warning. In order to resolve this warning we need
to fix our bug, but that's gonna be pretty tricky to find with just this
information. Luckily, that's where the next fairly common warning comes in.

## call

The second warning that we get for that code is:

{% highlight plain %}
lib/test.ex:9:call
The call:
Test.concat("string", :atom)

will never return since the success typing is:
(atom(), binary()) :: binary()

and the contract is
(atom(), String.t()) :: String.t()
{% endhighlight %}

or:

{% highlight plain %}
lib/test.ex:9: The call 'Elixir.PotionProxy.Client.MainWorker':concat(#{#<115>(8, 1, 'integer', ['unsigned', 'big']), #<116>(8, 1, 'integer', ['unsigned', 'big']), #<114>(8, 1, 'integer', ['unsigned', 'big']), #<105>(8, 1, 'integer', ['unsigned', 'big']), #<110>(8, 1, 'integer', ['unsigned', 'big']), #<103>(8, 1, 'integer', ['unsigned', 'big'])}#,'atom') will never return since the success typing is (atom(),binary()) -> binary() and the contract is (atom(),'Elixir.String':t()) -> 'Elixir.String':t()
{% endhighlight %}

This example really shows how much more helpful the new formatting is!

So, what this warning is telling us (and telling us much more clearly in the new
formatting) is that we're calling `concat/2` with `"string"` and `:atom` as
arguments, but that it will never return if we call it with those arguments.

Ok, now we're getting somewhere - this looks like it's the function call that's
causing our bug! The unfortunate thing here is that this warning is directly
related to the `no_return` warning that we just went over, but there's sadly no
connection to that in the messages. In the message for `no_return` it was
warning about `call_concat`, but now in the message for `call` it's warning
about `concat`. At first glance these two warnings don't seem connected, and yet
they are.

The one helpful thing that's always good to keep in mind is that the warnings
are **grouped by file** and **ordered by line number**, so if you see a
`no_return` warning and then below that a `call` warning a couple lines down in
the same file, there's a good chance the two warnings are related somehow.

So, back to that warning. It's saying that what we're trying to do is never
going to work. It then tells us what the success typing is for that `concat/2`
function, which in this case is `(atom(), binary()) :: binary()`, and the
contract for that function which is slightly different
`(atom(), String.t()) :: String.t()`.

The difference between a success typing and a contract is the success typing is
the absolute minimum requirement that Dialyzer has worked out that are
necessary for that function to not fail, while the contract is the requirement
for using that function that a human programmer has written. Because humans
frequently make mistakes, and because Dialyzer's success typing is sometimes not
able to be as specific as a human, it's generally a good idea to take whichever
of the two options is more strict when you're deciding on how to use a
particular function. In this case, `String.t()` is more strict than just
`binary`, so you should probably only call `concat` with strings and not any old
binary.

So, how to resolve this warning? Well, you need to use the function according
to how that functions wants to be used! In this case, we need to change
`concat("string", :atom)` to `concat(:atom, "string")` so the arguments are in
the correct order. Once we've done that we can re-run Dialyzer and see that we
now have no more warnings - bug found and fixed!
