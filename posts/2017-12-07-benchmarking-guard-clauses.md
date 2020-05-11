---
title: Benchmarking guard clauses 
tags: Elixir Benchmarks Surprises 
description: I was lying in bed last night and for some reason I remembered this issue that was opened in July. I remembered, "Hey, I should add that to fast-elixir!" and
date: 2017-12-07 00:18:00
---

I was lying in bed last night and for some reason I remembered [this issue](https://github.com/elixir-lang/elixir/issues/6374) that
was opened in July. I remembered, "Hey, I should add that to fast-elixir!" and
so today I did. I said that in general pattern matching is faster than guard
clauses, and one should prefer pattern matching to guard clauses if possible.
Turns out, I was pretty wrong. While using `length/1` in a guard clause is
indeed a less-than-optimal decision, there's much more nuance to be discovered
here.

The always helpful Michał Muskała took a peek at my example and raised some [very
valid concerns](https://twitter.com/michalmuskala/status/938772737623052288). I
poked around further, benchmarked some other examples with [Benchee](https://hex.pm/packages/benchee),
and boy was I surprised at the results!

## elem/2

So this is the first real surprise I found. Let's look at the two following
examples:

##### Example 1
```
defmodule Counter.Guard do
  def tup(input) when elem(input, 0) == :ok, do: 0
  def tup(_), do: 1
end
```

##### Example 2
```
defmodule Counter.PatternMatch do
  def tup({:ok}), do: 0
  def tup(_), do: 1
end
```

I'm not usually a betting man, but I would have put money on the pattern
matching version being at least a little faster than the one with `elem/2` in
the guard clause. But I whipped up a benchmark, and it turns out that's not the
case at all!

```
Name                       ips        average  deviation         median
guard clause           38.67 K       25.86 μs    ±45.43%       23.00 μs
pattern matching       30.04 K       33.28 μs    ±85.16%       28.00 μs

Comparison:
guard clause           38.67 K
pattern matching       30.04 K - 1.29x slower
```

Semantically that's the exact same code, but the pattern matching version is
almost 30% slower. This is even more surprising given how common it is to
pattern match on the first element of a tuple - I would have expected that to
be a very highly optimized operation.

However, this trick is only good when it's a single expression in the guard
clause. In the following example, the guard clause version was almost 15%
slower.

##### Example 1
```
defmodule Counter.Guard do
  def tup(input) when elem(input, 0) == :ok and elem(input, 2) == :hi, do: 0
  def tup(_), do: 1
end
```

##### Example 2
```
defmodule Counter.PatternMatch do
  def tup({:ok, _, :hi}), do: 0
  def tup(_), do: 1
end
```

## map_size/1 and tuple_size/1

Since `length/1` is slow in guard clauses, then it makes sense that `map_size/1`
and `tuple_size/1` should be slow too, right? WRONG! They're actually super fast
in guard clauses! Let's look at another example.

##### Example 1
```
defmodule Counter.Guard do
  def size(tup) when tuple_size(tup) == 2, do: 0
  def size(_), do: 1
end
```

##### Example 2
```
defmodule Counter.PatternMatch do
  def size({_, _}), do: 0
  def size(_), do: 1
end
```

This time the runtimes were a little closer together, but still the guard clause
was a little bit faster. 

```
Name                       ips        average  deviation         median
guard clause           40.38 K       24.77 μs    ±47.22%       22.00 μs
pattern matching       37.35 K       26.78 μs    ±65.15%       24.00 μs

Comparison:
guard clause           40.38 K
pattern matching       37.35 K - 1.08x slower
```

`map_size/1` is similarly optimized as a guard clause and has similar results.

## The lessons learned

Get creative with your benchmarks! Play around with different input sizes,
different functions or applications of a certain concept you're trying to
benchmark. And don't do what I did and jump to conclusions based on one or two
examples.
