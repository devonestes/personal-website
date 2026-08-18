---
title: Accepting incorrectness
tags: Engineering Management Quality
description: Nearly every conversation I've been in about software quality treats it as a tradeoff with speed. You can move fast, or you can be correct, and your job as a lead is to pick a point on that line and defend it. I've never really believed in this, and with AI speeding things up further this is a bigger topic. After a few years of being the person accountable for both the speed and the quality of what a team ships, I've come to think that bugs in production aren't really the problem here.
date: 2026-8-18 00:18:00
---

Nearly every conversation I've been in about software quality treats it as a tradeoff with speed.
You can move fast, or you can be correct, and your job as a lead is to pick a point on that line
and defend it.

I've never really believed in this, and with AI speeding things up further this is a bigger topic
on many teams these days. After a few years of being the person accountable for both the speed
and the quality of what a team ships, I've come to think that bugs in production aren't really the
problem here.

Your software is incorrect right now. Mine is too. There is a bug in production today that nobody
has noticed yet, and when you find it, it will turn out to have been there for months. And that's
not even counting the bad/confusing UIs that many folks ship and iterate on over time. That's not
a failure of "software quality," that's just what it's like to write software of any real size.
Shipping something wrong is not evidence of a low quality bar - it's evidence that you shipped.

So since mistakes will make it to production no matter how hard we try to avoid them (short of
something wild like formal verification), the interesting question isn't whether they exist, but
what we do when failure actually happens.

## The part that actually matters

The two biggest things I care about when it comes to deploying and operating production software
are my ability to quickly see problems in production and my ability to quickly fix them (usually
with a rollback of some sort).

Seeing problems in production means error tracking that someone actually reads, alerts that page a
human when the important things break, and enough observability to answer "when did this start?"
without a git bisect. Undoing it means small deploys, fast rollbacks, and feature flags on the
scary stuff - so that "we were wrong" costs you five minutes and has minimal production impact
instead of causing big problems for hundreds of thousands of customers and taking weeks to fix.

If you have those two things in place, then moving quickly and being occasionally wrong is a
perfectly fine strategy! It's arguably the _best_ strategy, because most of the time you don't
actually know if the thing you're building is right, and the cheapest way to find out is to put it
in front of people. A team that can detect and reverse its mistakes in minutes is allowed to make
a lot more of them.

## Where quality really goes wrong

The thing that I've seen that _really_ causes problems for software teams, though, isn't bugs
making it to production. It's the issue in the error tracker that's been firing a few hundred
times a day for eight months, and everybody scrolls past it to get to the new ones. It's the
log lines that everyone on the team knows to ignore through undocumented knowledge over months of
learning. It's the button in the admin UI that doesn't do anything but which your colleagues
_think_ actually does something, and the field that displays a number that hasn't been correct
since the last migration. It's the module nobody deletes because nobody is quite sure what will
break if it goes away.

None of those are really _bugs_ in the truest sense of the word. A bug in production is a thing
that happens. It's a bummer, but it's kind of unavoidable, and it's not really a problem as long
as it gets fixed quickly. **But tolerating bugs in production is a cultural issue that leads to
real problems.** At some point the team stopped caring, and that decision - made quietly, by
nobody in particular, over a period of months - is the actual quality problem. Not the number
of defects that have customer impact, but the number of defects that have almost no customer
impact but which keep creating noise and taking time away from real work.

And it compounds, in the specific way that hurts most: it eats your signal. The whole argument for
shipping fast rests on being able to see when you're wrong. An error tracker with four hundred
open issues can't tell you that something _new_ broke. An alert that fires every day has already
trained you to close it. Once "broken" is the normal state of your dashboards, you've lost the
thing that made moving quickly safe in the first place.

But more importantly, it sets the tone and the cultural expectations for what matters in your
engineering organization. The minute you onboard a new engineer and they see Sentry with 120 open
issues that haven't been touched, they see that keeping things running _well_ just isn't what
matters here. That sets the bar at a level that folks will unfortunately adapt to, and that
negatively impacts your ability to create great new things and to keep your existing things
running.

## So what do you actually do

Unless you're making software powering insulin pumps or flight controls, you can't expect to have
zero faults in production. If you try, you end up throwing good time after bad in an attempt to
achieve something that's not really even possible. The marginal return on all that time spent gets
lower and lower, meaning your team ends up functionally wasting time on things that don't matter.

The rule I've landed on is much cheaper than that: **noise is the real bug.** If an alert fires,
you either fix it or you silence it for good - and only silence it if you're _sure_ it can't be
indicative of a production issue. If the UI shows something that isn't true, we either fix it or
we cut it. The only thing worse than no data is _wrong_ data, and spending time every week
answering bug reports for the known thing that hasn't been fixed just adds up over time in a way
that's supremely unhelpful.

This is one of the reasons I haven't leaned too deeply into "data-driven management" - simply
because so much of the data we're using is incorrect! I'd rather make decisions knowing I don't
have correct data than hide behind incorrect data to justify my decisions. Counting faults in
production isn't the data we should be looking at when we talk about software quality (and don't
even get me started on things like "readability" or "scalability"). The thing that I've seen that
really moves the needle for teams is the cultural rejection of this kind of noise and the
ownership & accountability in a team to keep their systems running in good order. This unlocks so
many other massive benefits that I almost consider it a prerequisite to a team being able to do
actual product work!
