---
title: Building invisible systems
tags: Engineering Management Hardware Product
description: For most of my career, the software I was building was basically the entirety of the product the company sold. We worked with our colleagues in Product to decide what we would build next to serve our customers' needs, we wrote some code to solve those problems, and then we shipped it. It's easy to show impact when the value your team delivers is derived almost entirely from the software you ship to production.
date: 2026-8-30 10:00:00
---

For most of my career, the software I was building was basically the entirety of the product the
company sold. We worked with our colleagues in Product to decide what we would build next to serve
our customers' needs, we wrote some code to solve those problems, and then we shipped it. It's
easy to show impact when the value your team delivers is derived almost entirely from the software
you ship to production.

For the last couple of years, though, I've been leading the team that builds the software and
hardware behind Beat81's workout experiences (the screens and devices in our gyms that give
people real-time feedback while they're working out), and the thing about that which I still
sometimes struggle with for quite a few reasons is that at Beat81 **the software is not the
product**. People don't come to our studios for the software, they come for the exercise and the
community around that exercise.

A Beat81 workout can take place without the technology my team is building. In fact, that's how
the company first started! In the early days (when Beat81 workouts all took place outside) there
was just a coach, some basic fitness equipment, and a group of people who showed up to workout
together. That worked for a very long time without a single line of my team's code, but on the
flip side, our software doesn't work _at all_ without the workout. The dependency only points one
way, and that's created some challenges for me as a leader.

## Being an important part of something you're not the point of

I want to be careful here, because there's an obvious wrong reading. "You're not the product" can
sound like "what you build doesn't matter," and that's not it at all. What we build is a big part
of why people choose us over the gym down the street. We built these experiences based on the
feedback from many of the early participants of Beat81 workouts, and there are _many_ people that
say they continue to choose us because we're a technology-enhanced workout experience and they
love the feedback they get when they come to our studios.

But the _role_ of the software is different than at most companies I've worked at. When someone
uses a SaaS product, the software **is** the experience. The whole thing is an interaction between
a person and the software, and you want them conscious of that. In a workout, the participant came
to do the workout, not to watch a screen or push buttons on a tablet. Every second they spend
thinking about our screens instead of their next set is a second we've taken from the thing they
actually care about, and it can kill their ability to get lost in the experience and really get
into that awesome "flow state" that group exercise classes can offer. The best possible outcome
for our team is that participants get exactly what they need from us and never once need to think
about the tech.

So the goal is to get out of the way, which sounds easy until you realize what it does to
basically every single feedback loop you have as an engineering team!

## Success is invisible and failure is extremely visible

This is the part I'd tell any lead considering a job like this one.

When it works, nobody says anything. There is no thank-you email, no NPS bump you can attribute to
that release, no "wow this is so much better" tweet. The workout just happened the way it was
always going to. I've always said that this asymmetry is a big part of the reason why working in
security is so hard (and why I was always secretly happy I wasn't doing that), but I hadn't really
thought that this could also apply to product engineering!

When our tech doesn't work, it doesn't fail quietly in a log file. It fails in a room in front of
40 people who are hot & sweaty, and now they're looking at a screen that's broken, or who are now
standing uncomfortably in silence if the music stops playing mid-workout. Nobody has to file a
ticket for that failure to be felt. It gets felt immediately, by real people, in a location
potentially hundreds of kilometers away from our office.

That's an ugly asymmetry to hand a team of engineers, and it's on you as the lead to notice how
corrosive that can be over time if you don't actively do something about it. Engineers -
especially the really good ones - want to do work that matters. Here, "mattering" can sometimes
look like nothing is happening, and that's tough.

Luckily for us, we do have a few studios close to our offices, and so when we do develop new
features that enable new experiences we get to go and experience those things ourselves! We get to
be a part of the experience and see how fun it is, how it helps us push ourselves in our workouts,
and to see everyone else in the class feeling the same way. It's a pretty great feeling when we
build something new that helps folks achieve their fitness goals, or that enables coaches to give
more personalized feedback to participants, or something that frees up more time for our Front of
House staff to offer better hospitality experiences and help create that sense of community at our
workouts. In all those cases the workout is still the "main thing," but our role in enabling that
is still clearly seen & felt. We know that all of those things wouldn't be possible without our
work, and that feels great.

## The recovery window isn't yours to choose

I've written before about handling failure in software products, and I said that the two things I
care most about in that area are seeing problems in production quickly and being able to undo them
quickly. In a web app, "quickly" is a number you get to negotiate. Five minutes is great, an hour
is survivable, and for most bugs the honest answer is that you'll fix it in the next deploy and
almost nobody will have noticed in between.

There's no version of that here. A workout is a fixed block of time in a specific room with a
specific group of people in it. If something breaks at the start of it, you do not have "the next
deploy" - you have the length of that class, and then those people go home. Luckily for us, Elixir
gives us an incredible amount of runtime introspection tooling and the ability to resolve issues
without having to stop a workout. But even if we can fix the workout, a visible bug still likely
had a negative impact on the ability for someone to really enjoy that workout, and that's not what
we want.

This means that the recovery window for us is set by the class schedule, not by our development &
deployment pipeline. That reframing changed a few concrete things for us:

- **Degraded has to be a real, designed state, not an accident.** The question is never just "does
  it work?" It's "when this fails, does the workout still happen?" If the answer is yes, we have a
  bad afternoon. If the answer is no, we have ruined something for people who paid for it and
  arranged their morning around it. Those are not the same severity, and treating them as the same
  severity is how you spend your team's effort in the wrong places. We spent _a lot_ of time
  talking and planning for degraded experiences and handling failures when we're planning our
  work.

- **Rollback is necessary but not sufficient.** Reverting a bad deploy in three minutes is a fine
  outcome for a web app and only a partial outcome for us, because the class that started four
  minutes ago is already compromised. So a lot of our safety budget goes _earlier_ - into
  detailed testing plans, into progressive rollouts, into not shipping into the peak windows,
  and into things like looking at which features need to be gated behind feature flags for the
  ability to toggle them quickly in case of failure.

- **Our incidents have a timetable.** Load and risk aren't uniformly distributed across the day;
  they're stacked into the morning and evening blocks when classes are most full. That's a gift,
  in a way. You know exactly when you can be brave and exactly when you can't. It's a lot safer to
  do a test workout with 10 people at 14:30 than it is to do it with 60 at 18:00. Having this
  natural cadence to when our users go to our workouts gives us this opportunity to do safer
  "production tests" where the impact of failure is lower, and it also means there are some times
  when studios are completely empty that we can use to do tests in that environment without having
  to expose any users to possible failures.

## "Stakeholders" means something much bigger here

The other thing that took some time for me to really learn is how far outside of engineering &
product the dependency graph reaches.

At most software companies, "working with stakeholders" means product and sales, maybe support and
marketing if you're being thorough. You align on what you're building and roughly when it lands,
and then the release itself is basically an engineering event. You pick the day, and nobody
outside the team really has to _do_ anything for the feature to exist (unless you're timing the
release to a conference or something like that). That isn't _remotely_ true for us!

First: we can't ship a feature that changes what happens in a studio until our Front of House staff
and coaches know how to use it. They're the people actually running the room. If we quietly deploy
something that changes what they see or what a participant is going to ask them about, we haven't
shipped a feature - we've ambushed a colleague in front of a customer! So the release isn't done
when it's deployed; it's only done when it's successfully running in production. That means the
communication plan needs to be a part of the project, not just something that happens afterwards,
and it means the actual release date is a shared decision with a team that doesn't report to me
and has its own schedule and constraints.

Second: opening a new studio means our real estate team needs to know how much hardware to buy and
how the space should be laid out around it, months before anyone works out in that room. Where the
screens go, what people can see from where they're standing, what the room needs to physically
support - those are our decisions as much as theirs, and they get locked in long before we could
possibly have all the information we'd like. You can refactor your software, but you can't
refactor a wall. A choice we make casually in a planning conversation one day is still there, in
concrete, years later.

Neither of those is a communication problem you can solve with a better Slack channel or a status
update. They're genuine dependencies with lead times measured in months, on teams whose work has
nothing to do with software and who are quite reasonably not going to reorganize their quarter
around our work cadence. So a meaningful part of my job - a much larger part than in any previous
role I've had - is spent outside engineering entirely, and a big part of planning is figuring out
which of our decisions can change and which are permanent, and then making those permanent choices
visible and making sure _everyone_ is aligned there.

I'd argue that's made us better, not slower, and mostly for an unglamorous reason: it forces the
"what happens when this fails, and who's standing there when it does?" conversation to happen with
the people who'd actually be standing there. It's hard to ship a fantasy version of an experience
when the people who run that experience are in the room while you're designing it. They know what
actually happens, and they can give _great_ feedback before any of the things we're thinking about
ever make it in front of customers.

## The part that's actually about leadership

Everything above is really about answering one question, just asked different ways: **what is the
thing our users actually came for?**

If you're not it, then a lot of the default instincts of a good product engineering team need
adjusting. Engagement is not a goal - attention spent on us is attention not spent on the thing
they came for. Shipping more surface area is not obviously good. Your team's sense of impact can't
come from usage metrics, because the usage metric you want is closer to "they never had to think
about it."

A great example of this comes from our recent experience building our new Power Zones RIDE
workouts. For these we added an additional screen that shows personalized power & cadence metrics
for participants in our cycling classes, and we were _constantly_ asking ourselves about how much
information we wanted to put on that screen and how important it should be to the overall workout
experience. While that screen and the information it shows is indeed an important part of the
workout, we didn't want to take away from the rest of the experience which is so crucial - the
coach who is motivating them, the music that shapes the workout and creates the atmosphere, and
the ability for people to connect with others and feel part of a community. If folks are just
looking at their individual screens, that's going to come at a cost to those other things, and so
finding that balance took a lot of time & many iterations. Based on the feedback we've received so
far it looks like we found that sweet spot in the end, and it's an experience I'm incredibly proud
to have helped create.

I don't think this is as niche as it sounds. Plenty of teams are building the thing that supports
the thing: internal platforms, checkout flows, payments, the parts of a product that people move
_through_ on their way to what they actually wanted. If that's you, the trap is the same one I
fell into - measuring your work as if it was the destination and risking making the actual
destination worse in the process.

What I've found is that being explicit about it with the team helps more than anything else. Not
as false modesty, but as a design constraint, and honestly as a source of pride. The reason our
work is hard is that it has to be **excellent and invisible at the same time**. Anyone can be
excellent while demanding attention, but doing it while getting out of the way is a genuinely
harder product & engineering problem, and it's honestly a blast to work on solving these problems
with this extra level of difficulty added on top!
