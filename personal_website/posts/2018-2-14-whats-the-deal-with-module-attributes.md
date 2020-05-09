---
title: What's the deal with module attributes? 
tags: Elixir
description: I was recently doing some work on documenting and adding some missing typespecs to the Elixir codebase, and in that work I saw something that I thought I could improve.
date: 2018-2-14 00:18:00
---

I was recently doing some work on documenting and adding some missing typespecs
to the Elixir codebase, and in that work I saw something that I thought I could
improve.

{% highlight elixir %}
def default_options do
  [
    enabled: true,
    doc_bold: [:bright],
    doc_code: [:cyan],
    doc_headings: [:yellow],
    doc_inline_code: [:cyan],
    doc_table_heading: [:reverse],
    doc_title: [:reverse, :yellow],
    doc_underline: [:underline],
    width: 80
  ]
end
{% endhighlight %}

I thought "gee, why do we need to allocate a new list every time we call that
function? It would make sense to pull that out into a module attribute, right?"
I had noticed before that if I extract code like this out into a module
attribute it was slightly faster, so my guess was that the speed came from not
having to undergo the expensive allocation of memory and copying of this new
data into that new memory. Quick win, right? So I went ahead and pushed this up
for review as part of my documentation PR.

{% highlight elixir %}
@default_options [
  enabled: true,
  doc_bold: [:bright],
  doc_code: [:cyan],
  doc_headings: [:yellow],
  doc_inline_code: [:cyan],
  doc_table_heading: [:reverse],
  doc_title: [:reverse, :yellow],
  doc_underline: [:underline],
  width: 80
]

def default_options, do: @default_options
{% endhighlight %}

Well, José informed me that there is absolutely no memory difference between
these two versions of the same code. How could this be? And what accounted for
the difference in speed when using module attributes instead of literals in
functions?

There was one first big reason my understanding was incorrect here. I thought
that because all data in the BEAM was immutable, every time we called a function
we were passing a new copy of that value to the function. It turns out that
we're actually passing a reference to that value and not the value itself! This
is ok, though, because the data is immutable. If a bunch of places have a
reference to the same data it doesn't matter since it can't be changed.
Basically, I thought we were copying all the time, and it turns out we almost
never copy data (unless we're sending it to another process, which is why I
think I had this misconception in the first place - but with OTP 20 that's not
even the case anymore!).

So, we're pretty much never copying data when passing it within a single process
- only using references to that data to make new data! If you're not making
something new, you're not copying anything, even if you're calling a bunch of
functions with that same data. That's why a reference to data stored as a module
attribute and data stored as the return value to a function pretty much makes no
difference.

But this still doesn't explain the difference in the speed. Well, it turns out
that what I _thought_ was a slight slowdown caused by copying was instead caused
by the slight amount of overhead involved in calling a function! Michał was
kind enough to break it down for me in a really great GitHub comment, so instead
of parroting that here, I'll just [link to it](https://github.com/elixir-lang/elixir/pull/7259#issuecomment-360743057).
And that performance hit of calling a function is _sooo_ small that it's barely
worth counting. Even in a very hot path, this is going to be barely noticeable.

So, given this, why do we need module attributes? Frankly, I'm no longer 100%
sure. I thought that they would be used like constants in Ruby, as a sort of
outer-scope declaration of a reference to a value so you don't need to copy so
much. Heck, that use case is even explicitly described in the [Elixir docs](https://elixir-lang.org/getting-started/module-attributes.html#as-constants)
(but without the reasoning of avoiding copying data).

Those docs also point out the two other really good use cases, which are using
them for annotation or for temporary storage during compilation. Sometimes it's
easy to forget `@doc`, `@spec` and the like aren't really much more than a
module attribute!

I guess there's still some value in using module attributes as constants since
they provide a message to the developer reading the code about how they're
supposed to be used, but without a performance benefit I'm less sure if this is
a really desirable use case. What's the real benefit here over a function?

### Addendum

After I posted this, of course Michał shared a really good use case for
constants stored as module attributes instead of a function.
{% twitter https://twitter.com/michalmuskala/status/964113147299880960 %}
