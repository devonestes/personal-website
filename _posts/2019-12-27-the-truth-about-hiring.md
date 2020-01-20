---
title: The truth about hiring
tags: Elixir Hiring Business
description: It's the end of the decade, and I'm breaking from my normal technical posts for something different that's been bugging me for the last couple of months. 
date: 2019-12-27 00:00:00
---

It's the end of the decade, and I'm breaking from my normal technical posts for
something different that's been bugging me for the last couple of months. I
speak to a lot of people that are involved in recruiting and hiring decisions,
and one of the things I hear all the time is "we use Python/Java/JavaScript
because there are so many developers, so it's much easier to hire." I also hear
things like "Elixir developers are hard to find." The thing is, both of these
things are technically _wrong_, and that's what I'm going to go over today.

_N.B. I'm going to make some assumptions on numbers in this post. These
assumptions are going to be shown in **bold**. If you want to plug in your
numbers and re-run my formulas, go for it, but I don't think my assumptions (at
least in relative terms) are off by more than an order of magnitude, and only if
I were off by an order of magnitude would my thesis here be wrong._

## "We have an easier time hiring with a larger pool of developers"

It's a global fact that hiring software developers is a difficult business. It's
worse in some places (the US) than others (Europe/India/Africa), but I don't
think there is any market in the world (local or global) where the number of
available developers is greater than the number of open jobs. For the sake of
this post, let's assume that there are **20,000** open software development
jobs, and **10,000** software developers currently without work.

Now, out of those **10,000** available software developers, it's likely that
**5,000** of them know JavaScript, **4,000** of them know Java, **3,000** of
them know Python, **3,000** of them know C# (or some other DotNet language),
**1,000** know Ruby, and maybe **100** know Elixir (developers frequently know
more than one language, hence the total being higher than 10,000). There are
also a bunch of other languages out there with similar user bases to Ruby, and
many more with similar user bases to Elixir, but we're just focusing on these
for now.

Yes, on the whole Elixir is a tiny, niche language. There are not many
developers compared to the other languages. This leads companies to say "if we
choose JavaScript/Java/Python we'll have an easier time hiring - look at all
these developers we have to choose from!" This is a totally reasonable thing to
thing to assume, but this doesn't mean you'll have an easy time actually
_hiring_ one of those developers!

Because this line of thought is so common, that means that out of the 20,000
open software development jobs, there are probably **7,000** for JavaScript,
**5,000** for Java, **4,000** for Python, **2,500** for DotNet, **750** for
Ruby, and **50** for Elixir. So, while there are indeed many available
JavaScript developers, there are _far more_ jobs for those developers, meaning
that while you might be able to get 40 candidates in the door for interviews,
you'll have a really hard time getting any one of those 40 candidates to
actually choose your company in the end. This drives up a company's cost since
the competition is so fierce, resulting in wasted time (and money) in the
interviewing process, and additional cost because the salaries are going to be
higher in the face of all that competition. If you're trying to hire a
JavaScript developer you have a 71% chance of getting one, an 80% chance of
getting a Java developer, a 75% chance of getting a Python developer, and an 83%
chance of getting a DotNet developer.

But look at those other two! You've got 1000 Ruby devs for 750 Ruby jobs, and
100 Elixir devs for 50 Elixir jobs. This means that - if you can find 3 or 4 of
those 100 Elixir devs, you've got a pretty darn good shot at getting one of them
to sign, and they'll probably be really happy just for the opportunity to use
Elixir on a daily basis!

_N.B. This is totally analogous to the infamous [Tickle Me Elmo craze](https://en.wikipedia.org/wiki/Tickle_Me_Elmo#1996_Elmo_craze) of 1996,
where 1,000,000 toys were made and were in such high demand that they ended up
being sold for thousands of dollars, and even then thousands of children were
terribly disappointed by not seeing Elmo under the Christmas tree that year._

Now if you do the math, a 75% chance of hiring one of 40 Python developers works
out for you just fine. But this isn't the whole story, since we know all
developers aren't equal to one another. Some have 10 years of experience, and
some have just graduated from college. Some have great communication skills, and
some don't. These differences, combined with the somewhat accepted belief that
the size of the worldwide pool of developers doubles every 4 years (meaning that
at any given time 50% of devs worldwide have less than 4 years of experience)
are what have created the really intense competition for the mythical Senior
Developer!

## Hiring seniors

Elixir isn't taught in college (except for that one course Dave Thomas teaches
at SMU), which means you're not going to find college grads for Elixir jobs.
Elixir's community of developers is almost entirely made up of folks with 5+
years of experience. I remember back in 2017 when I spoke at RailsConf and
ElixirConf EU within a couple days of each other, and I noticed that at
RailsConf I was often the oldest person in the room and often had the most
experience, but at ElixirConf EU I had never been in a room with so many PhDs
before, and I was frequently the youngest person in the room.

Because the problems that Elixir solves really well are just really difficult
problems, it attracts the types of folks looking for that kind of challenge.
Sure, it can do the same stuff that Ruby can do just fine, but there are
additional thing that Elixir is great at (distribution, soft real-time systems,
etc.) that tend to attract these types of senior developers.

Meanwhile, Java, Python and JavaScript are used extensively as teaching
languages in college, meaning that there are tens of thousands of new grads each
spring looking for jobs. So, out of the 4,000 available Java developers, maybe
**1,500** of them have 4+ years of work experience. Meanwhile, out of the 100
available Elixir devs, probably **90** of them have 4+ years of experience. So,
if you're looking to hire experienced, senior developers, you've got a great
chance of getting one in Elixir vs. in these other languages where "hiring is
easier."

This is what has - in my opinion - made success stories like WhatsApp and
Basecamp possible. These companies did a ton of work with very small teams of
very senior developers because they were using languages that (at the time for
Basecamp, and still today for WhatsApp) had small but available hiring pools of
very experienced developers. You're now starting to see this in Elixir more and
more with companies like Brex, Discord and Podium starting to get really big
with relatively small teams of senior Elixir developers.

Now that these teams are growing quite large and they need a headcount that
might outnumber their local market's supply, they're also learning that
training junior developers in Elixir isn't any more difficult than training
junior developers in any other language. Basically, Elixir was a huge help in
getting them off the ground, but it's not a hindrance is helping them go from
successful to hugely successful.

So, if you're one of these people who are in charge of hiring for your company,
or are a technical leader in these situations and concerned about hiring and
training, take a second look at your assumptions about hiring. It's not just a
numbers game, and sometimes going and finding 4 great candidates for an Elixir
position is actually going to be faster and _easier_ than combing through 40
candidates for a Python position and then maybe not even getting one of the
four that you actually really wanted to hire because there were 9 other
companies all trying to hire those four folks!
