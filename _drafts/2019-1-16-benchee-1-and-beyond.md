---
title: Benchee 1.0 and beyond!
tags: Elixir Benchee Benchmarking Performance
description: We're getting really close to a release of Benchee 1.0! We have a release candidate out now, as well as a version 0.99 that includes deprecations for everything that will be removed in 1.0 if you want to give them a shot.
date: 2019-1-16 00:18:00
---

We're getting really close to the release of Benchee 1.0! We have a release
candidate and a version 0.99 that includes deprecations for everything that will
be removed in 1.0 if you want to give them a shot. Both versions are up on Hex
now.

It's been a long time coming, but we're feeling really comfortable that the
current API isn't going to need to change again in the future. Of course those
are famous last words, but that belief is based on looking at the things we're
planning to add after 1.0 and seeing if we'd need to make any breaking changes,
and the good news is that with the currently planned additions, we won't need
to.

But those planned additions are what I really want to write about today, because
they're _super_ exciting! They're not listed below in any official order, but
they're basically in order of how much I personally want these new features.

## Reduction counting (and performance tests!)

The first thing I want to add is reduction counting for functions. If you're not
familiar with reductions, they're an internal abstraction of a unit of work for
the BEAM scheduler. You can think of one reduction as one function application.
A function that completes in 2000 reductions will be faster than a function that
completes in 5000 reductions - and that should hold true across all platforms!

So, you can think of reductions as another measure beyond wall time that tells
you how fast or slow your functions are.

Where I really want to take this, though, is to use reduction counting for
performance testing! Right now, performance testing is usually done with wall
time, which is **very** unreliable. The time a function takes to execute depends
on _so_ many things, from the specs of the machine running it, to the
configuration of the BEAM and what else is running. This is why, when we're
benchmarking, we try and collect tons of samples and then make some statistical
measurements to give us a better understanding of the big picture.

So, if we want to test that a very important function in a very hot code path
doesn't get slower, we need to use a fairly significant margin of error.
Otherwise, we'll get lots of false positive results, and the only thing worse
than slow code is flaky tests. This makes performance testing in this way fairly
low value.

But reductions are **constant**! Every time a function is run (as long as it's
deterministic), it will need the same number of reductions to execute! So, if
we're counting reductions, we can write performance tests that give us a very
accurate and reliable measure of a functions execution time. No more flaky tests
in CI when you have a noisy neighbor, no more 50% margins of errors - just
concreate information about your function's performance!

## More memory measurements

Right now we have memory measurements that tell us the total amount of memory a
function uses over the course of it's execution. This is a great measure, but
it's not the whole picture. For example, if you're processing a large file with
a stream instead of loading the whole file into memory before processing it, our
memory measurement will show that the stream uses more memory.

This is technically true, but even though it uses more memory over the course of
execution, it doesn't use nearly as much memory at any given time. So, we're
planning on adding two new memory measurements - Max Heap Size and Retained
Memory.

Max Heap Size will tell us the maximum size of the process heap during the
execution of the function you're benchmarking. This will be a fairly good proxy
for how much of an impact your function will have on the BEAM's total memory
usage. The higher this measurement, the more memory your function will need to
actually allocate to do its job.

Retained Memory will be about how much memory is left on the process heap after
the function executes. In Elixir, this should be 0 for most cases, but it's very
helpful to know if your function does end up creating some retained memory for
some reason. This is a nice way to detect memory leaks.

In the beginning these new measurements will have the same constraints as the
current memory measurements - namely that they're only measuring the effect on a
single process. However, we are planning on expanding this so you can measure
memory usage in other processes involved in the execution of your function.

## Better support for property based benchmarking

I [wrote a few months ago](/benchmarking-with-stream-data) about how you can use
StreamData to write some interesting benchmarks with Benchee as it is today, but
we want to add better support for this. Basically, in the same way you can use
property testing to find bugs in your code, you can also use it to find
performance edge cases. We want to support this properly so it can be even more
useful.

These types of performance edge cases are typically found today by examining
logs and APMs that show us what's going on in production, but wouldn't it be
great if you could find those performance edge cases before your users do? Of
course, like property based testing, these benchmarks will take significntly
more time to set up, but, also like property testing, they hold enormous value.
