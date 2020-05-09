---
title: Benchmarking with StreamData
tags: Elixir Benchmarking Benchee StreamData
description: Recently my friend and benchee co-maintainer Tobi had an idea to use benchee to run benchmarks with random data
date: 2018-10-4 00:18:00
---

Recently my friend and benchee co-maintainer Tobi had an idea to use benchee to
run benchmarks with random data. This is an interesting idea, since you can get
what is probably a more accurate picture of how your function behaves with
real-world wierdness. It's essentially the idea of using different inputs for a
function, but turned up to 11.

While one thing we might do with this - to potentially find performance edge
cases in your code - will require some updates to Benchee (and that won't come
until we ship 1.0), there is another thing you can do right now if you want.


Let's say that we want to benchmark integer addition. We can think of a few
different combinations of integers to add, and use them as inputs, like this:

{% highlight elixir %}
Benchee.run(
  %{
    "add two integers" => fn {int1, int2} -> int1 + int2 end
  },
  inputs: %{
    "Small" => {1, 2},
    "Medium" => {1000, 10000},
    "Big" => {100_000_000, 1_000_000_000_001}
  },
  time: 5,
  memory_time: 1
)
{% endhighlight %}

And we might see results like this:

{% highlight text %}
Operating System: Linux
CPU Information: Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
Number of Available Cores: 8
Available memory: 15.39 GB
Elixir 1.7.1
Erlang 21.0

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 1 s
parallel: 1
inputs: Big, Medium, Small
Estimated total run time: 24 s


Benchmarking add two integers with input Big...
Benchmarking add two integers with input Medium...
Benchmarking add two integers with input Small...

##### With input Big #####
Name                       ips        average  deviation         median         99th %
add two integers       50.29 M       19.89 ns ±26068.89%           9 ns          62 ns

Memory usage statistics:

Name                Memory usage
add two integers             0 B

**All measurements for memory usage were the same**

##### With input Medium #####
Name                       ips        average  deviation         median         99th %
add two integers       42.62 M       23.46 ns ±25084.98%          13 ns          51 ns

Memory usage statistics:

Name                Memory usage
add two integers             0 B

**All measurements for memory usage were the same**

##### With input Small #####
Name                       ips        average  deviation         median         99th %
add two integers       41.91 M       23.86 ns ±25004.66%          13 ns          56 ns

Memory usage statistics:

Name                Memory usage
add two integers             0 B

**All measurements for memory usage were the same**
{% endhighlight %}

Ok, so we know that adding two integers is a VERY fast operation, and given the
super high deviation, we can see that adding to large integers is for some
reason a little faster than adding two small integers (N.B. again, because of
the super high deviation, I wouldn't put too much stock into this. It could be
true, but it might also be other things messing with the results.)

But, we've used a pretty limited set of inputs here. I think we could get REALLY
interesting results if we started using randomly generated data in our
benchmarks. To do this, we can use the `stream_data` library, which can generate
random data for us. We'll just use any random integer, since all integers can be
added together.

Then there's one important thing we want to do to make sure our benchmark is
accurate, and that's to make sure we're pulling off the stream **outside** of
our actual benchmark function. To do this, we can use the provided `before_each`
hook that benchee has, which allows you to execute a function before each
benchmark is run, and the result of that function gets passed to the function
being benchmarked. The time spent in the `before_each` function is **not**
counted towards the measured runtime.

So, then we can set our benchmark up like this:

{% highlight elixir %}
stream = StreamData.integer()
get_num = fn -> stream |> Enum.take(1) |> hd() end

Benchee.run(
  %{
    "adding two random integers" => fn {int1, int2} -> int1 + int2 end
  },
  before_each: fn _ -> {get_num.(), get_num.()} end,
  time: 5,
  memory_time: 1
)
{% endhighlight %}

And now we can see that our results are pretty darn similar to the ones that we
had when we specifically gave 3 inputs. The deviation is still super high for
such a fast operation, but we can clearly see that the average, median and 99th
percentile are all significantly higher than our previous results:

{% highlight text %}
Operating System: Linux
CPU Information: Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
Number of Available Cores: 8
Available memory: 15.39 GB
Elixir 1.7.1
Erlang 21.0

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 1 s
parallel: 1
inputs: none specified
Estimated total run time: 8 s


Benchmarking adding two random integers...

Name                                     ips        average  deviation         median         99th %
adding two random integers           42.97 M       23.27 ns  ±3428.47%          18 ns          48 ns

Comparison:
adding two random integers           42.97 M

Memory usage statistics:

Name                              Memory usage
adding two random integers                 0 B

**All measurements for memory usage were the same**
{% endhighlight %}

So, which pairs of nubmers were the fastest and slowest? That we'll have to
answer at a later time once we add that feature to benchee, but for now we can
use this technique to get a better picture of a function's real-world
performance. Of course you need to make sure the random data that you're
generating is representative of a the real-world usage of your function, but for
many functions this might end up being a more accurate way of getting a picture
of your function's performance!
