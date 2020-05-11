---
title: Local Metrics Aggregation With Counters
tags: Elixir Erlang Telemetry Metrics Performance
description: Recently I needed to get a better picture of how my application's database connection pool was doing, but there was a bit of a hitch. DBConnection has a highly optimized queuing algorithm, but the downside of that optimization is that you can't get an accurate picture of the number of idle and busy connections in the pool at any given time like you can with Poolboy.
date: 2020-5-1 00:18:00
---

Recently I needed to get a better picture of how my application's database connection pool was
doing, but there was a bit of a hitch. `DBConnection` has a highly optimized queuing algorithm,
but the downside of that optimization is that you can't get an accurate picture of the number of
idle and busy connections in the pool at any given time like you can with `Poolboy`.

The good news is that it _does_ emit some `telemetry` events that you can use as a fairly good
proxy for those measurements. If you attach to `[:my_app, :repo, :query]`, you'll get measurements
called `queue_time` and `idle_time` (starting with `ecto_sql` 3.3.0) that you can use to get a
picture of if your queries are waiting in a queue for a connection or how long they were idle
before being used. If you have a huge `idle_time` then you can probably get away with a smaller
pool size, but if you have a small `idle_time` or periods with higher `queue_time`s then you might
need a bigger pool size.

But this comes with another catch! The app I'm instrumenting has quite a high throughput (~750
RPS), and if I'm going to send these metrics to our external metrics collection service on every
query we make, we're quickly going to be using a _lot_ of IO just for those. One answer is to set
up a local aggregation server like `statsd` or the Datadog Agent that runs on your host and then
forwards the aggregated metrics to the service at some interval.

But I'm a big fan of keeping things simple when it comes to ops, and setting up another thing that
involves configuration files is the last thing I want to do. Luckily, there's a way we can do this
really well and easily with just what's built-in to Erlang (starting with OTP 21.2) and Elixir.

## The solution

Before I go into my solution, I should note that the gist of this solution was José's and not
mine. There's no way I'd come up with something this good on my own, so thanks to him for the tip
on how to make this really efficient. So, below is a GenServer that you can use as a local
aggregate server, but in OTP!

```
defmodule Telemetry.LocalAggregation do
  @moduledoc """
  Module to handle local aggregation of collected custom metrics.

  Because these functions are going to be called _very_ often, we are using some pretty serious
  performance optimizations to make sure collecting and processing these metrics doesn't
  contribute too much to slowing things down in the app.
  """

  use GenServer

  # This offset is what allows us to keep the count and the aggregate value in the same counter
  # for a given metric. We use the last 20 bits to keep the total count and the first 44 bits to
  # keep the measurements. This will give us storage for 1 million entries before it is reset. The
  # offset for the last 20 bits is 17592186044416.
  @counter_offset 17_592_186_044_416

  # Counter lists in Erlang are 1-indexed, and they're always a list of counters. We're only ever
  # using counter lists with only a single counter.
  @index 1

  ## PUBLIC API ##

  @spec start_link(pos_integer(), function(), System.time_unit()) :: GenServer.on_start()
  def start_link(aggregate_interval_in_ms, publish_fun, publish_time_unit \\ :millisecond) do
    args = {aggregate_interval_in_ms, publish_fun, publish_time_unit}
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec add_event(String.t(), non_neg_integer(), System.time_unit()) :: :ok
  def add_event(name, value, time_unit \\ :native) do
    GenServer.cast(__MODULE__, {:add_event, name, value, time_unit})
  end

  ## CALLBACKS ##

  @impl true
  def init({aggregate_interval_in_ms, publish_fun, publish_time_unit}) do
    initial_state = {aggregate_interval_in_ms, publish_fun, publish_time_unit, %{}, tags()}
    state = schedule_send_aggregates(initial_state)
    {:ok, state}
  end

  @impl true
  def handle_cast({:add_event, name, value, time_unit}, state) do
    new_state = add_value(name, value, time_unit, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:send_aggregates, state) do
    new_state =
      state
      |> schedule_send_aggregates()
      |> send_aggregates()

    {:noreply, new_state}
  end

  ## HELPERS ##

  defp tags() do
    {:ok, hostname} = :inet.gethostname()
    %{hostname: List.to_string(hostname)}
  end

  defp schedule_send_aggregates(state) do
    {aggregate_interval_in_ms, _, _, _, _} = state
    Process.send_after(self(), :send_aggregates, aggregate_interval_in_ms)
    state
  end

  defp add_value(name, value, time_unit, state) do
    {aggregate_interval_in_ms, publish_fun, publish_time_unit, counters, tags} = state
    new_value = @counter_offset + value

    case Map.get(counters, name) do
      nil ->
        new_counter = :counters.new(@index, [:write_concurrency])
        :counters.add(new_counter, @index, new_value)
        new_counters = Map.put(counters, name, {new_counter, time_unit})
        {aggregate_interval_in_ms, publish_fun, publish_time_unit, new_counters, tags}

      {counter, _} ->
        :counters.add(counter, @index, new_value)
        state
    end
  end

  defp send_aggregates(state) do
    {_, publish_fun, publish_time_unit, counters, tags} = state

    for {name, {counter, record_time_unit}} <- counters do
      count = :counters.get(counter, @index)
      :counters.put(counter, @index, 0)
      value = avg_in_ms(count, record_time_unit, publish_time_unit)
      publish_fun.(name, value, tags)
    end

    state
  end

  defp avg_in_ms(0, _, _) do
    0
  end

  defp avg_in_ms(count, record_time_unit, publish_time_unit) do
    counts = div(count, @counter_offset)
    total = rem(count, @counter_offset)
    average = trunc(total / counts)
    System.convert_time_unit(average, record_time_unit, publish_time_unit)
  end
end
```

I benchmarked this solution, and it turns out to be as effective as I expected, and on my machine
the p99 for adding a measurement is 1 microsecond, which I think isn't too bad!

```shell
Operating System: macOS
CPU Information: Intel(R) Core(TM) i9-9980HK CPU @ 2.40GHz
Number of Available Cores: 16
Available memory: 32 GB
Elixir 1.10.0
Erlang 22.3.2

Benchmark suite executing with the following configuration:
warmup: 1 s
time: 10 s
memory time: 0 ns
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 11 s

Benchmarking add_value...

Name                ips        average  deviation         median         99th %
add_value        2.28 M      438.04 ns  ±4644.31%           0 ns        1000 ns
```

The real fun and interesting stuff going on here is in the add_value/3 helper there.

```
defp add_value(name, value, time_unit, state) do
  {aggregate_interval_in_ms, publish_fun, publish_time_unit, counters, tags} = state
  new_value = @counter_offset + value

  case Map.get(counters, name) do
    nil ->
      new_counter = :counters.new(@index, [:write_concurrency])
      :counters.add(new_counter, @index, new_value)
      new_counters = Map.put(counters, name, {new_counter, time_unit})
      {aggregate_interval_in_ms, publish_fun, publish_time_unit, new_counters, tags}

    {counter, _} ->
      :counters.add(counter, @index, new_value)
      state
  end
end
```

We're using the `:counters` module from Erlang, which gives us highly optimized 64 bit signed
integers that we can perform super fast operations on. But since we're doing an aggregation (in
this case, just using the average of the values over the configured time), we need both the count
of events and the total of those events. With a little bit of thinking, we can store both of those
values in the same number by using an offset! By adding `@counter_offset` there, we're using the
first 44 bits to keep the running sum of measurements for a given metric, and the following 20
bits to keep the count of events. This means we can store up to about 1 million events before
those bits overflow and reset, which is _more_ than enough for pretty much all cases.

There might be little bits of customization here and there for different metrics providers or
things like that, but the above solution is generalized enough to work for most applications, and
pretty extensible for additional kinds of aggregations or metrics. Either way, aside from having
another OS process running on your host and sending it UDP packets with this kind of info, I don't
think you'll find a more highly optimized solution to this problem than this!
