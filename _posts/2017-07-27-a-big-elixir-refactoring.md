---
title: A Big Elixir Refactoring 
tags: Elixir Refactoring 
date: 2017-07-27 00:18:00
---

I've just finished my first really substantial refactoring of someone else's
code in Elixir. I wanted to make some changes to Benchee so that it would be
easeir to add another feature later on. We needed a new data model, and there
were some concepts that I felt needed a little shaking out and naming.
Today I'm going to cover some of the reasons for this refactoring, as well as
some of what I learned both specifically and in general about refactoring
in Elixir.

## TLDR;

Refactoring in Elixir is wonderful! It might be slightly more verbose than in
some other languages, but each step in the refactoring is simple and explicit.
Error messages are helpful, and there wasn't a single difficult. In my eyes,
more simple things is preferable to fewer complex things, and this refactoring
confirmed my existing beliefs about one of the key benefits of Elixir: changing
existing code is very easy.

## The problem

Before this refactoring, the main data structure in Benchee was a deeply nested
map. While this was a simple thing that allowed for some nice, clear recursive
processing of jobs, because we were frequently iterating over this map using
`Enum.map/2`, this made changing the format of that map kind of difficult. If we
needed to change that map's structure, then we'll also need to change a lot of
existing functions. We wanted to change this structure to also (optionally) start
measuring memory usage information.

Also, as someone who was still fairly new to the codebase, it seemed at first
glance like this was a really important data structure and domain concept, but
it wasn't clearly named.

## The process

I started out by first doing two [spikes](https://github.com/PragTob/benchee/pull/86)
on adding that memory usage information. Both of them came out kind of weird,
and I didn't like the implementation at all. These spikes were very helpful,
though, since they showed exactly what kinds of problems we were encountering
and gave a great starting off point for considering how to solve those pain
points. This led to another [spike](https://github.com/PragTob/benchee/pull/93)
on a potential refactoring. In that spike I got to shake out some ideas and play
around with a couple different solutions. It was imperfect, but it was another
really good exploration, and it started a really good conversation.

The next step was for Tobi and I to have a chat about that spike. We did this in
person since we both happen to live in Berlin (and also because I work remotely,
so it's nice to actually sit with someone every now and then. Side note, if you
are in or near Berlin and want to pair on OSS stuff, let me know!).
We discussed what we liked, our concerns, and potential ways to improve my spike.
What came out of that conversation was some identification of some previously
unnamed concepts in the codebase (namely, the idea of a Scenario and a Scenario
Context). Instead of representing these as various combinations of keys and
values in that nested map, we decided to represent them as a list of structs.
Iteration over these structs was just as easy as iteration over the nested map
(I would say even easier), but now each struct had everything in it that it
needs to be understood as a single domain concept. It also meant that adding 
keys to these structs in the future wouldn't require changes to any existing
code (which was the big reason to move to structs in the first place).

So, now that we had an idea of what the end solution might look like, I got to
implementing it. First there was [a PR](https://github.com/PragTob/benchee/pull/95)
to just add in the basic concept of the `Scenario` without acutally using it,
just to try and break up what was going to be a big process into some smaller
steps. This was a pretty easy PR since it was non-breaking and just additive.
I didn't have to change much in the way of existing code. I also didn't have
much in the way of tests to update, but I did add some tests for the new code.

Then the [second PR](https://github.com/PragTob/benchee/pull/96) was to switch
over to actually using that new data structure to store all the information we
were collecting in our benchmarks. This was a bigger feat, so I again tried to
break it down into smaller pieces. I decided to go module by module,
updating the unit tests for each module to use the new data strctrue, and then
doing the refactoring to make those tests pass for that one module. Each commit
would be one step in this process.
I did _not_ change any feature/integration tests - I would skip any that broke,
and my assumption was that when I was done with the unit tests, all the feature
tests would be green again. This turned out to be true for all but one test that
explicitly was testing validity of the old nested map data structure. This is
because _technically_ this is a breaking change to the public API since any
plugins for Benchee will need to be updated to use this new data structure.

## The takeaways

In general, this was a really lovely experience. The big thing I took away from
it was how simple (in a Rich Hickey kind of definition) the process was. Not
once during the process did I have to sit back and think "wait, WHAT is going on
here?!" That's something that I need to do with unfortunate frequency in Ruby
code. The clarity and explicitness of each step was a breeze, and because each
module is so decoupled from each other one, I could easily break
this large piece of work up into several smaller ones. Honestly, there were many
points where I could sort of mentally "check out" and not have to really think, and I was
still doing the right thing. **It felt almost mechanical at times.**

Some might find this kind of work boring, but I would personally rather write
boring, functional software versus complex, buggy software. It might be a
personal preference, but I'd rather make 10 boring, simple changes than 2 large,
complex changes. I think that's a sign of good, maintainable software, and you
can still solve interesting problems in simple, boring, effective ways.

At each step of the process, there was _never_ a time where a change I made in
one module broke tests for another module. The only tests that ever failed were the
feature/integration tests, and once I was done refactoring each module,
those Just Worked™.

**I cannot state enough how big of a deal this is. Coupling is what make software
complicated, and there was almost no coupling between units in this code base.**
If you haven't seen Rich Hickey's talk on this topic, [_Simplicity Matters_](https://www.youtube.com/watch?v=rI8tNMsozo0),
I strongly encourage you to watch it.

This could be attributed simply to good design, and this is possible since the
primary author of Benchee I know to be an exceedingly good and thoughtful
developer. But, Tobi's skill aside, I think it's more than just good design. I
believe this is an example of what Elixir applications just are. Whereas in
other languages it's easy to have tight coupling between units, in Elixir it's
actually somewhat difficult. You need to start reaching deeper in to some more
advanced concepts like Protocols and Behaviours to start introducing tigher
forms of coupling between units.

**I believe that Elixir is simple by default and you need to work to make your
application complex, while applications in many other languages are complex by default
and you need to work to make them simple.** I believe this
refactoring illustrates that well, but I'd love to hear what others think!

Now, on to updating those plugins!
