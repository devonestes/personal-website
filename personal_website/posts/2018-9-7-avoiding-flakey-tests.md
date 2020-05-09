---
title: Avoiding flaky tests in Phoenix
tags: Elixir ExUnit Testing Tests
description: There is far and way a single assertion in ExUnit that is responsible for more test flakiness than any other. It's probably the culprit for more than half of all test failures that shouldn't fail.
date: 2018-9-7 00:18:00
---

There is far and way a single type of assertion I've see that is responsible for
more test flakiness than any other. It's probably the culprit for more than half
of all test failures that shouldn't fail.

Can you guess what it is?

{% highlight elixir %}
assert list == [user_1, user_2, user_3]
{% endhighlight %}

It also has a cousin that is responsible for many other test failures when in
fact nothing should have failed.

{% highlight elixir %}
assert [%User{id: ^user_1_id, posts: posts} | _] = data
{% endhighlight %}

Why are these tests often the source of flakiness? Well, if you're dealing with
Phoenix applications, you're potentially dealing with a database. And if you're
dealing with a database, you might be selecting things from that database. And
if you're selecting things from that database, and you don't have an explicit
`ORDER BY` clause in your query, then there is **no guarantee** for the order in
which your records are returned!

Sure, most of the time your tests run this might not fail, as the default
behavior for many databases is to return the records in the order they're stored
on disk, and if you created `user_1` before `user_2`, you'll probably get them
in that order most of the time. But it's _much_ better to be explicit in
avoiding this possibility of flakiness, which also does a better job of
describing the behavior of the function you're testing. Otherwise you're
accidentally testing for a certain order of data even if that order isn't
necessarily part of the behavior you need.

To solve the first case above, you can write a function called
`contains_exactly/2` in a module with some helper functions which will assert
that the data you expect to be the contents of a list
really is the content of that list, but without asserting the order:

{% highlight elixir %}
def contains_exactly(list_1, list_2) do
  list_1 -- list_2 == [] and list_2 -- list_1 == []
end
{% endhighlight %}

It's just a wrapper around two boolean checks, but it gives a good name to
what you're doing and reads well in your tests. It's also not a very high
performing function, but in most test data we're not usually dealing with dozens
or hundreds of records - usually just a couple.

So, unless the order of the lists you're asserting against is explicitly part of
the behavior of the function you're testing, it's best to avoid direct equality
comparisons of lists if possible!
