---
title: Bad ideas that aren't bad anymore
tags: Engineering Management Leadership AI
description: I've been working in software for about 15 years now, and over that time I've made a lot of mistakes and learned from a lot of other people's mistakes. This experience is a deep well that I can draw from when discussing possible solutions for both technical and non-technical problems. This is how I know what sorts of solutions sound good in theory but run into problems in practice, or what fringe idea is actually a perfect fit for the problem we're trying to solve here. This knowledge & experience is a big part of what has made me effective as a leader.
date: 2026-11-6 12:00:00
---

I've been working in software for about 15 years now, and over that time I've made a lot of
mistakes and learned from a lot of other people's mistakes. This experience is a deep well that I
can draw from when discussing possible solutions for both technical and non-technical problems.
This is how I know what sorts of solutions sound good in theory but run into problems in practice,
or what fringe idea is actually a perfect fit for the problem we're trying to solve here. This
knowledge & experience is a big part of what has made me effective as a leader.

Lately, though, a lot of the things my gut tells me are bad ideas are turning out to work really
well. In our team's retro this week that hit me pretty hard, and it was a real learning moment for
me. It made me realize that a big chunk of the intuition I've been relying on might not be worth
as much as I thought anymore, and that I need to question that experience more frequently.

So I wanted to write down a few of the "bad ideas" that we're doing right now that are actually
working really well, and then to try and figure out what that means for people like me.

## Nobody reviews anybody else's PRs

For pretty much my whole career, code review has worked the same way: one person writes the code
and opens the PR, and then somebody else on the team reviews it before it gets merged. The second
set of eyes catches bugs, spreads knowledge around the team, and keeps any one person from
quietly drifting the codebase off in their own direction. Merging your own PR without review was
one of those things that was a "break glass in case of emergency" kind of situation.

About a month ago we changed that completely. We had been struggling with code review due to the
increased pace of PRs being opened, and so we decided to try something crazy - just not doing it.
Now the engineer working on a ticket works with Claude, which then opens the PR, and then the
human working on the ticket reviews Claude's work. Once CI is green & the Greptile review is
clean, if the human working on the ticket feels confident that the solution is solid, they merge
the PR. That's it. No waiting on a teammate to find time to context switch into your change, no
pinging people in Slack to please take a look.

And it's been working great! When I actually think about _why_ it works, it's because the thing
that code review was protecting against is still being protected against. There's still a second
set of eyes on every change - it's just that the author is Claude and the reviewer is the human
who owns the ticket. That human understands the problem better than anyone else on the team,
because they're the one who's been working on it. They're a much better reviewer for that change
than a teammate who has to page in all the context from scratch. But also, Claude & Greptile are
just better at finding the kinds of things that are often found in Code Review, like small bugs or
inconsistencies. It's pretty rare (at least on the teams I've worked on) for big things like
architectural flaws or unintended product impact to be found at this stage.

I've [written before](/trust-collaboration-and-basketball) about how review gates can be a sign
of a lack of trust, so maybe I shouldn't have been so surprised that removing one worked out. But
my gut still said "you can't just merge stuff without somebody else looking at it," and my gut
was wrong. At least so far that's been true - we're only one month into the change, but it's
feeling really good so far.

## Splitting the team up across separate streams of work

This is the one that came up in our retro. Recently we had a few people out on holiday, and at the
same time we had a couple of parallel and fairly separate streams of work going on. So we split
it up, and basically each person owned one stream of work and ran with it.

Historically I really haven't liked doing this. When everybody on a team is working on a different
thing, you get knowledge silos. Only one person knows how the thing they built works, and if they
leave or get sick or go on holiday, the team is stuck. Even worse, I think it erodes the feeling
of actually being a _team_. You're not working together to solve the same problem anymore, you're
just a group of people solving different problems at the same time who happen to share a standup.
I've pushed back on this kind of setup on basically every team I've led.

But in the retro, we talked about it, and we're just not seeing any of the consequences I was
worried about - at least not in terms of knowledge silos. And the reason is that it's become so
easy to get up to speed on someone else's work. If I need to jump into something a colleague has
been working on, I can say to Claude "hey, bring me up to speed on this thing they've been
building - how does it work, where is it at, and what still needs to be done?" A few minutes later
I have what I need to start contributing. I don't need anybody else to onboard me, and I don't
need to spend a day reading through code to figure out what's going on.

The thing that's really changed here is that **the cost of context switching has dropped
dramatically, because we're operating a level higher than we used to.** I don't really need to
context switch into the specific code and how it works (or at least not that much to get started).
What I _do_ need to context switch into is the problem. As long as I have a conceptual
understanding of the problem that we're trying to solve, and roughly the shape of the solution
we're going for, I can jump in and be useful.

Will there be some long-term consequences of working this way that we haven't seen yet? Maybe! I'm
honestly not sure. But "maybe there's a problem we haven't seen yet" is a very different argument
than the one I'd have made a year ago, which was "I'm pretty sure this is a bad idea and we'll
regret it."

## Don't go deep

This one is less about how my team works and more about the advice I give to the people I manage.

For a long time, my standard advice for engineers on their technical and professional development
was the classic "T-shaped" thing. First you build up a solid base of general engineering
practices, and then you pick one or two areas and go really deep on them. Become the performance
person, or the accessibility person, or the distributed systems person. Or pick a widely used
framework and become the expert in it - become a regular contributor to Rails or Phoenix and know
all the ins and outs of how it works. That kind of deep expertise used to be one of the most
reliable ways to make yourself really valuable.

Now I'm telling people pretty much the opposite. Deep expertise in a specific technology is a lot
less valuable when you have a collaborator that has read all of the source code for that framework
and can answer any question about it in a few seconds. This is another case (like what I mentioned
above) where _knowledge_ is less valuable, but where _judgement_ is still important.

What I'm recommending instead is to still build a _very_ strong foundation in engineering
fundamentals, because that's where I think we as humans offer the most value right now. That's
things like how to architect code, how to design good abstractions, and how to tell when an
abstraction isn't really fitting anymore. It's being able to look at something and say "this is
starting to get a little weak, and we should break it up," and then come up with what the right
abstraction should actually be. It's noticing that "it seems like we're missing something here
that needs a name," and being able to find that concept and name it. That's the stuff that keeps
the high-level architecture, the domain modeling and the data modeling at a high level of quality,
and that's where a good engineer really earns their keep these days.

But I'm also telling them that being great at the tech is now only one small part of the job.
Being great at the tech is no longer enough. You need to learn more about design. You need to
learn about product development and how to be a product manager, at least a little bit. You need
to get great at talking to users, doing research and really knowing the business.

I've always encouraged that on the teams I've led. I've believed for a long time that product
engineering was the best way to do this job. But I used to think of it as the thing that made
someone _great_, and now I think it's just table stakes. People who just write code, or who are
purely technical, are already much less valuable than they used to be, and I'm not sure how many
of those folks will be left in the profession five years from now.

## A few more I'm side-eyeing

Once I started looking for these, I started seeing them everywhere. These are a few others where I
haven't fully changed my mind yet, but where I'm a lot less sure of my gut than I used to be:

**Rewriting from scratch.** "Never do the big rewrite" is about as close to a universal law as we
have in this industry. But a lot of the reason rewrites were so dangerous is that they took
forever, and the old system kept changing underneath you while you were working on the new one.
If a rewrite takes days or weeks instead of years, a lot of that risk goes away.

**Building instead of buying.** I've talked a lot of teams out of building their own internal
tools when there's a SaaS product that does 80% of what they need. But when building the thing
that does exactly 100% of what you need takes an afternoon, that math looks pretty different.

**Building it three different ways.** Writing three different versions of the same feature and
throwing two of them away used to be an obviously silly waste of time. Now it's often the fastest
way to figure out which approach is actually right, rather than arguing about it in a design doc.
We can skip the "rough mockup" stage of product development and just A-B test with actual users in
production if we want, which is a much higher-quality test and leads to things being shipped
faster.

**Introducing a language or tool nobody on the team knows.** "We don't have anyone who knows Rust,
so we shouldn't use Rust" used to be a pretty much unassailable argument. I'm not so sure it is
anymore. Certainly if there are things that _require_ a certain language, like some of the
software we use at Beat81 for interfacing with some parts of our system. We don't have C#
knowledge on the team, but it's also the only driver available for a really good ANT+/BLE receiver
we wanted to use.

## What I actually got wrong

When I look at these together, I think the pattern is pretty clear. Each of these things was a bad
idea because of some cost. I _always_ think about things in terms of cost vs. benefit. Code review
by a teammate was worth it because the alternative was nobody else looking at the code at all.
Knowledge silos were bad because getting up to speed on someone else's work was slow and
expensive. Deep expertise was valuable because that knowledge was scarce and hard to get.

AI has changed a lot of those costs, and it's changed them really quickly. The rules that were
built on top of those costs don't automatically update when the costs change, though, and neither
does my intuition. My intuition was trained over 15 years in a world where all of those costs were
pretty stable, and so it keeps telling me things that _were_ true, with the same confidence it
always has.

That's what really got me in the retro this week. It's not that I was wrong about one thing (I'm
wrong _all_ the time). It's that the skill I've been using to decide whether things are a good
idea or not (which has been a big part of my success over my career) is now giving me bad answers
a lot more often than it used to.

So I'm trying to change how I use it. When my gut tells me something's a bad idea, I'm trying to
ask the follow-up question: **what's the cost that made this a bad idea, and is that cost still
there?** Sometimes it is, and the gut feeling is still right. But more and more often, the value
proposition may have changed. I'm certainly erring on the side of at least trying more experiments
for things I might have shot down in the past.

That's a weird thing to admit after 15 years of being paid, at least partly, for having good
instincts. But I think the leaders who are going to do well over the next few years are the ones
who can hold their experience a little more loosely, and who are willing to let their teams prove
them wrong. This is a time of _massive_ change for _everybody_, and so we've all got to adapt. Now
the thing that I think matters isn't who has the most experience & knowledge (although that still
carries some weight of course), but who can _adapt and learn_ the fastest to acquire new
experience & knowledge.
