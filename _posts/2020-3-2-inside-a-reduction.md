---
title: What's Inside a Reduction?
tags: Elixir BEAM OTP Internals Performance
description: I recently finished up the basics for a feature in Benchee that I had been pretty excited about for a while now - reduction counting! But after trying it out on my own for a bit to look for bugs and see how it could be best used so I could document the feature well, I pretty quickly ran into some confusing results. 
date: 2020-3-2 00:18:00
---

I recently finished up the basics for a feature in Benchee that I had been pretty excited about
for a while now - reduction counting! But after trying it out on my own for a bit to look for bugs
and see how it could be best used so I could document the feature well, I pretty quickly ran into
some confusing results. As it turns out, the results were correct and the implementation of the
feature is totally fine, but my understanding of how reductions could be used to measure
performance was flawed, and so that's what I wanted to share today.

This is a pretty low-level post, and to keep it short I'm not going to go explain what all these
terms mean in depth, but there are plenty of other good descriptions of these concepts out there,
so if you run into a word or a concept you aren't really familiar with, you would be well served
by doing a quick google to learn more about it before moving on.

## High expectations

The reason I was so excited about having reduction counting in Benchee was because it would give
us a consistent measure of performance that one could use to write really accurate performance
tests for highly performance sensitive functions. Wall-clock time is exceedingly difficult to use
for this because there are a nearly infinite number of factors that influence it, but reductions
are constant for a given function (assuming it's determinisitc) on a given architecture. This sort
of thing is exceptionally valueable for many applications, and not something that I'm really aware
of in any other language or runtime, so I thought this could be a really great thing for us to
have in our community.

When I got the feature implemented I ran our sort of cannonical benchmark, comparing
`Enum.flat_map/2` to `Enum.map/2 |> List.flatten/1`, and I saw the following results:

{% highlight text %}
Operating System: Linux
CPU Information: Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
Number of Available Cores: 8
Available memory: 15.39 GB
Elixir 1.10.0
Erlang 22.2.4

Benchmark suite executing with the following configuration:
warmup: 100 ms
time: 100 ms
memory time: 0 ns
reduction time: 100 ms
parallel: 1
Estimated total run time: 600ms


Name                  ips        average  deviation         median         99th %
flat_map         290.20 K        3.45 μs   ±129.24%        3.05 μs        7.06 μs
map.flatten      213.80 K        4.68 μs    ±35.18%        4.27 μs        8.83 μs

Comparison: 
flat_map         290.20 K
map.flatten      213.80 K - 1.36x slower +1.23 μs

Reduction count statistics:

Name        Reduction count
flat_map             0.61 K
map.flatten          1.28 K - 2.10x reduction count +0.67 K

**All measurements for reduction count were the same**
{% endhighlight %}

What I expected to see was a tight correlation between runtime and reduction count - essentially
I expected to see the same percentage of difference between runtime and reduction count. But as
you can see above, the reduction count for our slower version is 2.10x higher, but the wall-clock
time is only 1.36x slower. This means that my belief that we'd be able to use reduction count for
consistent peformance testing was flawed in some way. It looks like some reductions are much
faster than others.

But why?! I thought that on average all function calls would take roughly the same amount of time
to execute! Well, it turns out that couldn't have been farther from the truth.

## What's inside a reduction?

I was thiking about this as a lambda calculus problem, basically, where _all_ we have is
functions. I assumed that every function was mostly made up of calls to other functions, and that
they would all take roughly the same amount of time to execute. Even though I knew that BIFs exist
in the BEAM, and that these BIFs wouldn't be counted as reductions because they're implemented in
C in the BEAM itself, I figured that the distribution of these BIFs would be roughly equal.

So I dug a bit deeper. I used Michał Muskała's excellent [`decompile` package](https://github.com/michalmuskala/decompile) to take a look at the BEAM assembly generated
by a couple of functions, and I was frankly blown away by how much some functions rely on
instructions that aren't `call` and `call_ext` (which actually call functions).

For example, here are the BEAM instructions for `Enum.flat_map/2`:

{% highlight text %}
{function, flat_map, 2, 246}.
  {label,245}.
    {line,[{location,"lib/enum.ex",1054}]}.
    {func_info,{atom,'Elixir.Enum'},{atom,flat_map},2}.
  {label,246}.
    {test,is_list,{f,247},[{x,0}]}.
    {call_only,2,{f,255}}.
  {label,247}.
    {allocate,1,2}.
    {move,{x,0},{y,0}}.
    {move,{x,1},{x,0}}.
    {make_fun2,{f,1405},0,0,1}.
    {test,is_list,{f,248},[{y,0}]}.
    {move,nil,{x,1}}.
    {move,{x,0},{x,2}}.
    {move,{y,0},{x,0}}.
    {kill,{y,0}}.
    {line,[{location,"lib/enum.ex",2111}]}.
    {call,3,{f,1401}}.
    {jump,{f,253}}.
  {label,248}.
    {test,is_map,{f,252},[{y,0}]}.
    {get_map_elements,{f,250},
                      {y,0},
                      {list,[{atom,last},
                             {x,3},
                             {atom,first},
                             {x,2},
                             {atom,'__struct__'},
                             {x,1}]}}.
    {test,is_eq_exact,{f,250},[{x,1},{atom,'Elixir.Range'}]}.
    {test,is_ge,{f,249},[{x,3},{x,2}]}.
    {move,{x,3},{x,1}}.
    {move,{x,0},{x,3}}.
    {move,{x,2},{x,0}}.
    {move,nil,{x,2}}.
    {kill,{y,0}}.
    {line,[{location,"lib/enum.ex",2116}]}.
    {call,4,{f,491}}.
    {jump,{f,253}}.
  {label,249}.
    {move,{x,3},{x,1}}.
    {move,{x,0},{x,3}}.
    {move,{x,2},{x,0}}.
    {move,nil,{x,2}}.
    {kill,{y,0}}.
    {line,[{location,"lib/enum.ex",2118}]}.
    {call,4,{f,488}}.
    {jump,{f,253}}.
  {label,250}.
    {get_map_elements,{f,251},{y,0},{list,[{atom,'__struct__'},{x,1}]}}.
    {test,is_atom,{f,251},[{x,1}]}.
    {make_fun2,{f,1397},0,0,1}.
    {move,{literal,{cont,[]}},{x,1}}.
    {move,{x,0},{x,2}}.
    {move,{y,0},{x,0}}.
    {kill,{y,0}}.
    {line,[{location,"lib/enum.ex",3383}]}.
    {call_ext,3,{extfunc,'Elixir.Enumerable',reduce,3}}.
    {line,[{location,"lib/enum.ex",3383}]}.
    {bif,element,{f,0},[{integer,2},{x,0}],{x,0}}.
    {jump,{f,253}}.
  {label,251}.
    {make_fun2,{f,1399},0,0,1}.
    {move,{y,0},{x,2}}.
    {move,nil,{x,1}}.
    {kill,{y,0}}.
    {line,[{location,"lib/enum.ex",2127}]}.
    {call_ext,3,{extfunc,maps,fold,3}}.
    {jump,{f,253}}.
  {label,252}.
    {make_fun2,{f,1395},0,0,1}.
    {move,{literal,{cont,[]}},{x,1}}.
    {move,{x,0},{x,2}}.
    {move,{y,0},{x,0}}.
    {kill,{y,0}}.
    {line,[{location,"lib/enum.ex",3383}]}.
    {call_ext,3,{extfunc,'Elixir.Enumerable',reduce,3}}.
    {line,[{location,"lib/enum.ex",3383}]}.
    {bif,element,{f,0},[{integer,2},{x,0}],{x,0}}.
  {label,253}.
    {line,[{location,"lib/enum.ex",1065}]}.
    {call_ext_last,1,{extfunc,lists,reverse,1},1}.
{% endhighlight %}

That's a lot of non-function calls happening in there! All those instructions for `move`, `bif`,
`kill`, `get_map_elements`, `test`, `jump`, `allocate`, `make_fun2`, etc. are _not_ counted as a
reduction but still add to the function's actual wall-clock execution time. This means that if you
have a function that does a lot of stuff like this, you're going to see that function take a lot
longer to execute even though it still counts as only one reduction.

Here's another simpler example that I think really drives this point home. Below are two functions
that each count as one reduction when they're called:

{% highlight elixir %}
defmodule Test do
  def a_from_map(%{"a" => a}) do
    a
  end

  def a_from_map2(%{"a" => a}, %{"b" => b}, %{"c" => c}, %{"d" => d}) do
    [a, b, c, d]
  end
end
{% endhighlight %}

and here is the BEAM assembly for those functions:

{% highlight text %}
{function, a_from_map, 1, 8}.
  {label,7}.
    {line,[{location,"lib/test.ex",2}]}.
    {func_info,{atom,'Elixir.Test'},{atom,a_from_map},1}.
  {label,8}.
    {test,is_map,{f,7},[{x,0}]}.
    {get_map_elements,{f,7},{x,0},{list,[{literal,<<"a">>},{x,1}]}}.
    {move,{x,1},{x,0}}.
    return.


{function, a_from_map2, 4, 10}.
  {label,9}.
    {line,[{location,"lib/test.ex",6}]}.
    {func_info,{atom,'Elixir.Test'},{atom,a_from_map2},4}.
  {label,10}.
    {test,is_map,{f,9},[{x,0}]}.
    {get_map_elements,{f,9},{x,0},{list,[{literal,<<"a">>},{x,4}]}}.
    {test,is_map,{f,9},[{x,1}]}.
    {get_map_elements,{f,9},{x,1},{list,[{literal,<<"b">>},{x,5}]}}.
    {test,is_map,{f,9},[{x,2}]}.
    {get_map_elements,{f,9},{x,2},{list,[{literal,<<"c">>},{x,6}]}}.
    {test,is_map,{f,9},[{x,3}]}.
    {get_map_elements,{f,9},{x,3},{list,[{literal,<<"d">>},{x,7}]}}.
    {test_heap,8,8}.
    {put_list,{x,7},nil,{x,0}}.
    {put_list,{x,6},{x,0},{x,0}}.
    {put_list,{x,5},{x,0},{x,0}}.
    {put_list,{x,4},{x,0},{x,0}}.
    return.
{% endhighlight %}

And here's the benchmark I'm running:

{% highlight elixir %}
Benchee.run(
  %{
    "a_from_map" => fn ->
      Test.a_from_map(%{"a" => :a})
    end,
    "a_from_map2" => fn ->
      Test.a_from_map2(%{"a" => :a}, %{"b" => :b}, %{"c" => :c}, %{"d" => :d})
    end
  },
  time: 0.1,
  warmup: 0.1,
  reduction_time: 0.1
)
{% endhighlight %}

When I run the benchmark for these two functions we get the following results:

{% highlight text %}
Operating System: Linux
CPU Information: Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
Number of Available Cores: 8
Available memory: 15.39 GB
Elixir 1.10.0
Erlang 22.2.4

Benchmark suite executing with the following configuration:
warmup: 100 ms
time: 100 ms
memory time: 0 ns
reduction time: 100 ms
parallel: 1
inputs: none specified
Estimated total run time: 600 ms

Benchmarking a_from_map...
Benchmarking a_from_map2...

Name                  ips        average  deviation         median         99th %
a_from_map        38.31 M       26.10 ns   ±340.99%          24 ns          44 ns
a_from_map2       11.75 M       85.13 ns   ±353.75%          79 ns         137 ns

Comparison: 
a_from_map        38.31 M
a_from_map2       11.75 M - 3.26x slower +59.03 ns

Reduction count statistics:

Name        Reduction count
a_from_map                1
a_from_map2               1 - 1.00x reduction count +0
{% endhighlight %}

As we can see, our first function `a_from_map/1` only has 4 instructions in its assembly (ignoring
the function info in label 7), but the second function `a_from_map2/4` has 14 instructions (again
ignoring the function info in label 9), which explains why it runs ~3.5x slower - because there
are 3.5x as many instructions! And we see that again there are exactly the same number of
reductions for these two functions - **1**.

## What does this mean for this feature?

In short, I think this means that for the purpose I had in mind - performance testing - reduction
counting is basically useless. We can clearly see that the correlation betwen reductions and
runtime isn't there, and there is the potential for really bad false positives where the reduction
counts are equal (or fewer!) but the runtime is significantly higher.

Also, the functions where this sort of testing would be most important are also the most likely to
rely more directly on BIFs and other non-reduction operations since those are significantly faster
to execute given that they're implemented in C directly, so using reduction counting to test those
functions wouldn't be helpful at all and potentially misleading.

This doesn't mean that this information is all entirely without merit, though! If you're trying to
optimize a function like this that is an extremely hot path and pretty far down the stack, you
could use the reduction count and looking at things like the BEAM instructions to replace
reductions with BIFs and other, faster ways of doing things. Essentially, you could look at the
reduction count as a guide in your optimization work - but that's also not something that most
developers will be doing in their production applications. That sort of optimization really only
belongs at the language level, and _maybe_ at the library level to a very limited extent.

But then again, there could be some other way that this might be helpful to folks that I haven't
considered, so for now I'm generally leaning towards documenting this behavior and releasing it. I
would be interested to see what this gets used for, and hopefully it adds some nice value to the
community and solves someone's problem.

So even though it doesn't look like this is going to work out the way that I had hoped, it's
still cool to learn some new things about the BEAM and how we can analyze our code to help make it
better and faster, so it wasn't a total waste!

## Postscript

Want to see something really crazy, but also kind of cool?! Let's expand a bit on our previous
`Test` module above and add a third function that will take two reductions:

{% highlight elixir %}
defmodule Test do
  def a_from_map(%{"a" => a}) do
    a
  end

  def a_from_map2(%{"a" => a}, %{"b" => b}, %{"c" => c}, %{"d" => d}) do
    [a, b, c, d]
  end

  def a_from_map3(map) do
    do_a_from_map3(map)
  end

  defp do_a_from_map3(%{"a" => a}) do
    a
  end
end
{% endhighlight %}

Now, here's the assembly for those functions:

{% highlight text %}
{function, a_from_map, 1, 8}.
  {label,7}.
    {line,[{location,"lib/test.ex",2}]}.
    {func_info,{atom,'Elixir.Test'},{atom,a_from_map},1}.
  {label,8}.
    {test,is_map,{f,7},[{x,0}]}.
    {get_map_elements,{f,7},{x,0},{list,[{literal,<<"a">>},{x,1}]}}.
    {move,{x,1},{x,0}}.
    return.


{function, a_from_map2, 4, 10}.
  {label,9}.
    {line,[{location,"lib/test.ex",6}]}.
    {func_info,{atom,'Elixir.Test'},{atom,a_from_map2},4}.
  {label,10}.
    {test,is_map,{f,9},[{x,0}]}.
    {get_map_elements,{f,9},{x,0},{list,[{literal,<<"a">>},{x,4}]}}.
    {test,is_map,{f,9},[{x,1}]}.
    {get_map_elements,{f,9},{x,1},{list,[{literal,<<"b">>},{x,5}]}}.
    {test,is_map,{f,9},[{x,2}]}.
    {get_map_elements,{f,9},{x,2},{list,[{literal,<<"c">>},{x,6}]}}.
    {test,is_map,{f,9},[{x,3}]}.
    {get_map_elements,{f,9},{x,3},{list,[{literal,<<"d">>},{x,7}]}}.
    {test_heap,8,8}.
    {put_list,{x,7},nil,{x,0}}.
    {put_list,{x,6},{x,0},{x,0}}.
    {put_list,{x,5},{x,0},{x,0}}.
    {put_list,{x,4},{x,0},{x,0}}.
    return.


{function, a_from_map3, 1, 12}.
  {label,11}.
    {line,[{location,"lib/test.ex",10}]}.
    {func_info,{atom,'Elixir.Test'},{atom,a_from_map3},1}.
  {label,12}.
    {call_only,1,{f,14}}.


{function, do_a_from_map3, 1, 14}.
  {label,13}.
    {line,[{location,"lib/test.ex",14}]}.
    {func_info,{atom,'Elixir.Test'},{atom,do_a_from_map3},1}.
  {label,14}.
    {test,is_map,{f,13},[{x,0}]}.
    {get_map_elements,{f,13},{x,0},{list,[{literal,<<"a">>},{x,1}]}}.
    {move,{x,1},{x,0}}.
    return.
{% endhighlight %}

And here's the benchmark I'm running:

{% highlight elixir %}
Benchee.run(
  %{
    "a_from_map" => fn ->
      Test.a_from_map(%{"a" => :a})
    end,
    "a_from_map2" => fn ->
      Test.a_from_map2(%{"a" => :a}, %{"b" => :b}, %{"c" => :c}, %{"d" => :d})
    end,
    "a_from_map3" => fn ->
      Test.a_from_map3(%{"a" => :a})
    end
  },
  time: 0.1,
  warmup: 0.1,
  reduction_time: 0.1
)
{% endhighlight %}

It would be totally reasonable to think that the new `a_from_map3` function would probably come in
between the two previous functions, right? It's doing the same thing as `a_from_map` but just
adding an extra function call around it, which means it should take more time because it's doing
more computation, right?

Wrong! Check this out:

{% highlight text %}
Operating System: Linux
CPU Information: Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
Number of Available Cores: 8
Available memory: 15.39 GB
Elixir 1.10.0
Erlang 22.2.4

Benchmark suite executing with the following configuration:
warmup: 100 ms
time: 100 ms
memory time: 0 ns
reduction time: 100 ms
parallel: 1
inputs: none specified
Estimated total run time: 900 ms

Benchmarking a_from_map...
Benchmarking a_from_map2...
Benchmarking a_from_map3...

Name                  ips        average  deviation         median         99th %
a_from_map3       43.84 M       22.81 ns   ±693.56%          19 ns          42 ns
a_from_map        32.75 M       30.53 ns   ±507.99%          28 ns          49 ns
a_from_map2        9.18 M      108.89 ns   ±609.02%          81 ns         311 ns

Comparison: 
a_from_map3       43.84 M
a_from_map        32.75 M - 1.34x slower +7.73 ns
a_from_map2        9.18 M - 4.77x slower +86.08 ns

Reduction count statistics:

Name        Reduction count
a_from_map3               2
a_from_map                1 - 0.50x reduction count -1
a_from_map2               1 - 0.50x reduction count -1
{% endhighlight %}

The BEAM has dozens of ways of optimizing applications both at compile-time and at runtime, so
when it comes to performance optimization on the BEAM, never guess and always measure! There are
tons of ways that the BEAM can surprise us to make our code run way faster than we think it
should.
