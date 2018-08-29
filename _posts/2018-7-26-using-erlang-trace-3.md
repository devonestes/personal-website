---
title: Using :erlang.trace/3 to listen to garbage collection events 
tags: Elixir
description: I recently did a lot of traveling, which is why I haven't written for a while. In those travels, I got to meet some new Elixir friends, and we even went over some code together.
date: 2018-7-26 00:18:00
---

I recently did a lot of traveling, which is why I haven't written for a while.
In those travels, I got to meet some new Elixir friends, and we even went over
some code together. One thing I showed a couple folks was the code around
measuring memory in Benchee. They were kind of confused at what's happening
there, so I figured others might not have found it as easy-to-understand as I
did, and I wanted to write up something to spread the knowledge around.

Right, so [here's the code on GitHub](https://github.com/PragTob/benchee/blob/f20a518dc98a6c51fd2ad77f2829c98c36fb53ef/lib/benchee/benchmark/measure/memory.ex)
that I'll be going over. Give it a quick read - it's not all that much code.
We'll walk through what's happening first at a high level, and then we'll look
at a couple details that some folks found interesting.

## A quick gist

Ok, so that module has a single public function (`measure/1`), that accepts a
function to be benchmarked. We then start spawning some processes, first in
`start_runner/2`, and then again in `start_tracer/1`. I'll try and explain
what's going on here with a little picture.

![process tree](/assets/images/process_tree.png)

So we end up with three processes, one as a sort of de facto supervisor (which
is the main process), and then a runner process that actually executes the
function that we're benchmarking, and a third tracer process that receives
messages about garbage collection events taking place in the runner process.

So, that's the process tree that we set up to do our work. Let's get a little
bit deeper into the details.

## The real meat - using :erlang.trace/3

Ok, so the coolest thing happening here is the use of `:erlang.trace/3`. This
function tells the BEAM to set certain tracing flags, either on a given process
(which is what we're actually doing), on all new processes, or on all existing
and new processes. So, when we call `:erlang.trace(pid, true,
[:garbage_collection, tracer: self()])`, we're basically telling the BEAM, "Hey,
I would love it if you would send me all the data you have on garbage collection
events for the pid that I just gave you every time an event happens. Thanks!"
Processes are very nice - they always say please and thank you 😉

And then our tracer calls `tracer_loop/2`, goes into into its `receive` loop,
and waits ⏳

Meanwhile, back in our runner process, we're now actually running the function
that we want to benchmark! Well, first we use `Process.info(self(),
:garbage_collection_info)` to find out how much memory our runner process has
allocated directly before we execute our function, and then we get to running the
function we want to benchmark. 

And while that function is being run, every time a garbage collection event
happens, our tracer is receiving messages and storing that info for later. The
messages that it's receiving are a keyword list that look something like this:

{% highlight elixir %}
[
  old_heap_block_size: 0,
  heap_block_size: 233,
  mbuf_size: 0,
  recent_size: 0,
  stack_size: 13,
  old_heap_size: 0,
  heap_size: 220,
  bin_vheap_size: 0,
  bin_vheap_block_size: 46422,
  bin_old_vheap_size: 0,
  bin_old_vheap_block_size: 46422
]
{% endhighlight %}

All those values stand for the amount of memory (in words, not bytes!) allocated
for those various things. There are two types of messages that we get for each
event - a `before` and `after` message, giving us the heap and old_heap size
before and after garbage collection took place. We then do a little bit of math to
determine how much data was garbage collected away, add that to the running
total we're keeping, and go back to listening for more events.

Fun aside - because the BEAM uses a generational garbage collector, there are
two heaps! So, when you see `heap_size`, that's only the heap with the newest
generation of data. Kind of a confusing name, right? That was actually the
source of a bug for a little bit. Anything that lives long enough to be moved to
the old generation is counted in the `old_heap_size`.

Ok, so now the function has finished, and our runner process again calls
`Process.info(self(), :garbage_collection_info)` to find out how much memory is
allocated directly after executing the function. We then ask our tracer for that
running total of how much memory was garbage collected during the run of our
function. We add that up with the amount of memory still on the process heap,
and we have our number of how much memory was allocated during the function that
we wanted to benchmark!

So, that's the gist of what's going on in our memory measurement process in
Benchee. I think it's really cool, and tracing is a great way to collect
information about a running system.
