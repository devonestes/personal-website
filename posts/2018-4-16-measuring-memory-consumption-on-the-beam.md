---
title: Measuring memory consumption on the BEAM 
tags: Elixir Benchmarking BEAM Memory 
description: Benchee 0.13 was released this weekend, and in that release there's one feature that I'm SUPER excited about. Starting with this release, you can now benchmark memory usage in Elixir or Erlang functions!
date: 2018-4-16 00:18:00
---

Benchee 0.13 was released this weekend, and in that release there's one feature
that I'm SUPER excited about. Starting with this release, you can now benchmark
memory usage in Elixir or Erlang functions! Because after all, performance isn't
_just_ about run time. Memory consumption counts, too!

### The basics

So, if you want to measure memory usage, you use Benchee just like you normally
would, but you also need to say how long you want to measure memory for:

```
map_fun = fn num -> num + 1 end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(1..1000, map_fun) end,
  "map.flatten" => fn -> 1..1000 |> Enum.map(map_fun) |> List.flatten end
}, memory_time: 2)
```

For the vast majority of the functions you're going to benchmark, you don't need
to run the measurement for very long since most of the time functions use the
exact same amount of memory each time they're run. Only when there's some sort
of randomness in your function will the memory usage vary.

### The small print

So, while this is super cool, it's not yet perfect. The biggest catch is that
the way we have memory measurement implemented at the moment, it can only
measure the memory usage of a single process in which the original function is
executed. So, while the above example will give you a really accurate measure of
the total memory used in a process, it doesn't give you the effect on the BEAM
VM as a whole. For example, if you're spawning a bunch of processes to do some
calculations for you in parallel, you won't see that memory usage in your
measurements. Yet. I'd love to get there eventually, but for now it's not in
scope.

Also, we're measuring the total memory used in a function, not just the net
effect on the size of the process's allocated heap. That means every byte that's
garbage collected as part of the running of the given function counts towards
the total memory usage of the function.

Oh, and this feature is only supported in OTP 19 or higher, since it uses a
tracing function only introduced in that version.

### How it's done

In many garbage collected languages, you can turn off the garbage collector if
you like. Not so with the BEAM. If you wanted to turn off garbage collection,
you'd crash the VM pretty darn quick, which is why it's not even an option.
Usually, in those other runtimes, if you want to measure memory usage, you just
turn off garbage collection, measure your VM size, run your function, measure
your VM size again, and then take the difference. Easy peasy, right?

Since we can't do that, we needed another way. Here's the gist of how it works.

First, we spawn a process to listen to some messages from `:erlang.trace/3`.
Specifically, we're listening to all garbage collection messages. Thanks to
those messages, we can get the size of the heap before and after garbage
collection to find out how much data was garbage collected. We keep track of
that throughout the entire run of the function being benchmarked, and at the
very, very end we find out what's left that on the heap and add that in, too. 

If you want to check out the specifics, it's actually not all that much code -
and you can see it [here](https://github.com/PragTob/benchee/blob/master/lib/benchee/benchmark/measure/memory.ex).
