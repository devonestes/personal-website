---
title: The problem with definitions
tags: Engineering Management Leadership Metrics
description: I was at LeadDev Berlin earlier this month, and a lot of the conversations kept circling back to metrics. The thing I kept coming back to, though, is that pretty much all of these metrics work just fine in theory. The problem is that every one of them depends on a handful of definitions, and these definitions are where things start getting a bit tricky.
date: 2026-11-13 12:00:00
---

I was at LeadDev Berlin earlier this month, and a lot of the conversations kept circling back to
metrics. How do you measure your team's productivity? Which of the DORA metrics actually matter?
How do you show the rest of the business that engineering is getting better over time? How are we
measuring ROI on AI spend?

The thing I kept coming back to, though, is that pretty much all of these metrics work just fine
in theory. The math is simple, the dashboards are pretty, and the reasoning behind each one makes
sense. The metrics themselves aren't really the problem. The problem is that every one of them
depends on a handful of definitions, and **the definitions are where things start getting a bit
tricky.**

## When does the clock start?

Take cycle time. The idea is simple: how long does it take us to get from an idea for something
that needs to be done to the point where that solution is running in production? Shorter is
better, longer is worse, track it over time and see if you're improving.

But what is your starting point there? Is it the moment someone says "huh, we should really do
something about that" in a meeting? When the ticket gets created? When it's been refined and
estimated and put on the board? When an engineer finally moves it to "In Progress"? Plenty of
tickets sit in a backlog for months before anybody touches them - did the clock start some months
ago? What about all the product research and ideation that happens before the work even hits your
engineering team? If the clock didn't start at that first moment, then you're not really measuring
"idea to production" anymore. You're measuring "the point where we decided to actually do it to
production," which is a different and much less interesting number because it doesn't reflect
anything about how well the _business_ turns ideas into value for customers. You're just measuring
how quickly the _engineers_ turn tickets into software, and that on its own has little value since
engineering is such a small part of the overall business cycle (especially now with AI).

And "in production" isn't any easier. Is it when the PR is merged? When it's deployed? Deployed
behind a feature flag that's still turned off? Turned on for 5% of users? Turned on for everybody,
except the mobile release with the other half of the feature is still waiting on App Store review?
And when part of what you're building runs on hardware bolted to a gym wall, "in production" gets
blurry in some really fun new ways.

Each of these is a perfectly defensible answer. You can pick one, write it down, and get your team
to agree to it. But then the actual work starts happening, and the work doesn't care about your
definition.

## The exceptions are the normal case

Here's what actually happens to a ticket. It gets started, and then something urgent comes up, so
it sits there half-finished for two weeks. It gets split into three tickets halfway through
because it turned out to be bigger than anyone thought. It gets shipped, and then reopened a week
later because a piece of it was missing. Meanwhile a hotfix goes straight to production at 9pm
without a ticket at all because something was on fire.

None of these cases are rare, and it doesn't necessarily reflect on inefficiencies or deficiencies
in process or skills. This is just what work looks like! Life, work and people are all messy and
hard to categorize. But every one of those is a case that your definition either doesn't cover, or
covers badly. So you've got three options for each one:

1. Force it into the definition anyway, and get a number that's technically correct and
   practically meaningless.
2. Exclude it, and bias your data toward the work that went smoothly - which is exactly the work
   you have the least to learn from.
3. Add a rule for it.

And if you keep picking option three, eventually your definition of "cycle time" is a two-page
document that nobody has read except the person who wrote it, and everybody on the team is
applying it a little bit differently anyway.

That's where the noise in these metrics comes from. Not from bad tooling or lazy data entry, but
from the fact that the normal, totally unavoidable messiness of the real work doesn't fit into the
boxes we built to measure it.

## What even is a bug?

It gets even worse for the metrics that are supposed to tell you about quality. Change failure
rate, bug counts, incident counts, escaped defects - these all need you to define what a
_failure_ is, and that's a much harder question than when the clock starts.

So what's a bug? The easy answer is "the software doesn't do what we intended it to do." Fine. But
what about when it does what we intended, just badly - it's slow, or it's confusing, or it works
on the third try? What about when it does _exactly_ what we intended, and the intention was wrong?
We built the feature exactly to spec, and the users hate it, or can't figure out how to use it, or
are using it for something completely different than we expected. From the user's point of view,
that's a bug. They're filing support tickets about it. So is a design problem a bug? Is a product
problem a bug?

There's no right answer here! If you pick a narrow definition, your bug count looks great while
your users are frustrated about a bunch of things that "aren't bugs." If you pick a broad one,
your bug count turns into a measure of how many opinions everybody had about the product this
month. And if you land somewhere in between, then every time something new comes in, somebody has
to make a judgement call about which side of the line it falls on, and that often leads to finger
pointing on who "owns" the problem and can cause problems between teams.

Incidents have the same problem. Is it an incident if customers were affected? How many customers?
For how long? What about when an alert fired and somebody fixed it before a single customer
noticed? That's arguably the system working exactly as it's supposed to (I've
[written before](/accepting-incorrectness) about how detecting and fixing problems quickly matters
way more than never having them), but it might also be the most important near-miss you had all
quarter.

And once people know the definitions, the definitions start shaping the work. Nobody has to be
acting in bad faith for this to happen. If something only counts as an incident when customers
were affected for more than 15 minutes, there's going to be a lot of quiet pressure to argue that
_this_ one didn't really count.

## Software is binary. People aren't.

I think a big part of why we keep reaching for these metrics comes from who we are as engineers.
We spend all day in a world that's very black and white. A test passes or it fails. We don't write
tests that sometimes pass, or that are allowed to fail under certain conditions (and when we
accidentally do, we call them flaky and we hate them). A huge part of the job is taking fuzzy
requirements and turning them into precise, unambiguous definitions that a computer can execute.

So it's pretty natural to assume we can do the same thing to the _process_ of building software.
Define the states, define the transitions between them, measure the time spent in each one. But
that process isn't run by computers, it's run by people, and people don't fit into boxes nearly as
neatly. We get pulled onto other things. We change our minds. We discover halfway through that the
problem is actually a different problem. We have to go to the hospital at 3:00am and have
emergency surgery to remove our appendix which is about to burst (a true story that happened to
me, by the way!). A definition that could really capture all of that would have to be so fuzzy that
it couldn't produce a useful number at all.

## So what do I do with this?

I'm not saying we shouldn't measure anything. But I've said before that I'd rather make decisions
knowing I don't have correct data than hide behind incorrect data to justify my decisions, and
that's pretty much where I've landed here too. A few things that I think help:

- **Treat the number as a question, not an answer.** If cycle time jumped last month, that's a
  great reason to go talk to the team about what happened. It's not a conclusion on its own.
- **Look at the outliers, not the averages.** The work that doesn't fit the definition isn't
  noise to be filtered out. It's usually the most interesting thing in the whole dataset - that's
  where the stuck work, the surprise complexity, and the misunderstood requirements are hiding.
- **Compare a team to itself, not to other teams.** Two teams will apply the same written
  definition differently, every single time. A trend within one team is a lot more trustworthy
  than a comparison between two of them. Teams can also have very different constraints which can
  make their numbers look different even though they are doing their work equally well.
- **Agree on roughly what you mean, and stop there.** Getting a team to a shared, rough
  understanding of what counts as a bug is really valuable. Spending weeks arguing about edge
  cases to make the definition airtight isn't, because it never will be. The cost of the argument
  just isn't worth the benefit of the answer.
- **Try not to use bad metrics as KPIs.** This one is hard, but I think it's at least worth trying
  to avoid using metrics that we know are based on these kinds of messy definitions as KPIs.
  There are good metrics (usually business-level metrics) that are helpful for everyone to work
  towards, but tying the impression of performance to a metric that is known to be flawed is just
  a recipe for resentment and interpersonal issues.

The metrics everybody talks about at conferences aren't wrong, exactly. They're just built on top
of definitions that assume work is a lot tidier than it really is. If you know that going in, they
can still be useful. If you don't, you end up managing to a number that's mostly measuring how
well your team's work happened to fit into the boxes you drew.

Where I have seen metrics be _very_ useful is in places like operations, where you can easily
measure inputs and where the outputs have real business value. Decreasing the amount of empty
space on a cargo ship is an easy thing to measure and impacts the company's bottom line. Increasing
the average rating of your drivers as a ride share company directly means that customers are
happier.

They can also work very well in a small subset of product development. While measuring things like
developer productivity is hard, measuring things like how often customers interact with a new
feature or if a new UI element leads to increased checkout rates are comparatively easy! These
still rely on some _assumptions_, but at least the definitions are easy. There's no way to escape
assumptions, like the assumption that increasing customer happiness will lead to increased sales &
customer retention, but at least the definitions of the states are clear and simple there.
