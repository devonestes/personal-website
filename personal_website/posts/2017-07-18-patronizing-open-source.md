---
title: Patronizing Open Source
tags: OSS Economics 
description: In this week's episode of The Bikeshed, Sean Griffin went through some of his issues with funding open source work through services such as Patreon, which allow individuals or companies to contribute to an individual or group on a
date: 2017-07-18 10:18:00
---

In this week's episode of The Bikeshed, Sean Griffin went through some of his
issues with funding open source work through services such as Patreon, which
allow individuals or companies to contribute to an individual or group on a
recurring (usually monthly) basis. Well, all this talk of open source and money
got the amateur economist in me thinking, so here's my take on the topic.

## TLDR;

Open source is a market just like any other, and each project is essentially a
corporate entity, whether we like it or not. Those projects that offer the best
compensation will (theoretically) attract the highest level of talent and
succeed more than those that offer lesser compensation. However, compensation
can be more than monetary.

Open source has operated almost entirely on this model until now, but in recent
years the addition of monetary compensation for open source work and corporate
sponsorship has greatly changed the landscape. Patreon and other similar
services can be helpful, but unless the project is managed well, it might lead
to unhappiness and cause harm to the project.

## What is a market?

Let's take a step back and define a basic tenet of economics - what is a market?

> A market is commonly defined as a system, institution or procedure where people
> engage in the exchange of goods or services.

Basically, someone gives something, and someone else gives
them something in return. Markets exist naturally all over our society, and the
world of open source is itself a market. People's contributions (code, issue
triage, and any other kind of contribution) are the payments that they pay into
the market, and there are lots of kinds of compensation that they get in return
for their contributions. Below is just a limited list of possible types of
compensation for your contributions to open source software:

* Money
* Happiness/Joy
* Membership/Involvement in a community
* Increased reputation/fame/notariety
* Increased sense of self worth
* Decreased fear/anxiety
* Favorable perception in a professional environment (at work/looking for a job)
* More/better job opportunities

And like any market, those sellers that pay the most will probably end up with
the highest quality goods and services. It's no surprise that projects that are
backed by large corporations (like Rails, React, Kubernetes, Angular, etc.) are
some of the most successful in open source. Not only are many members of the
core teams of these projects paid to work on them full time, they also offer
significant compensation in other areas, such as increased fame/notariety,
membership/involvement in a community, and more/better job opportunities. When a
company is looking to hire someone, if you can list being a significant
contributor to some of these major projects on your resume, that's often a huge
benefit.

For some people, some of those forms of compensation probably have more value
than others. For example, I am paid well for my 9-5 work and have enough money,
but when I moved to Germany and found myself rather isolated and living in a
foreign land where I didn't speak the language, so being part of the
larger community of open source developers was really valuable for me.

## Selection bias

But aye, there's the rub. My needs matched what open source was offering, and so
I bought into that market. That's not the case for many developers - I would
even say for most developers. Open source started with well paid developers for whom
more money wasn't really all that necessary. Recently, however, the software
world has realized how exclusionary this is for large swaths of the broader
community of software developers.

Imagine someone who isn't particularly well paid at work, and
then outside of work they have a lot of responsabilities in their community. If
they're not particularly well paid, and they are already part of a community (or
family, or some other institution that gives that sort of emotional
nourishment), then working for free isn't going to be appealing to that person.
They have a community, but they need money, and for a very long time that isn't
what open source offered.

## Who's paying who?

Financial compensation is a tough nut to crack. Companies worldwide have been
trying to figure it out for centuries, and yet we still have huge groups of
people who are not paid what they're worth. But one thing remains constant with
financial compensation - the money has to come from somewhere. In open source,
funds primarly come from large companies which rely on the development of the
tools which their business uses. Think of Facebook and Google paying for the
development of React and Angular, respectively. There are lots of reasons why a
company might do this, but that can be saved for another post.

Then there's the trickier way of paying for this stuff, which is the crowd
funding route. One company isn't directly paying the do-er of the work, but
instead one or more entities (these could still be companies) band together to
fund either a project or an entity that funds multiple projects. For examples of
this, there is the Node.js Foundation, which supports the development of
Node.js, and then there's Ruby Together which supports the development of
several important parts of the Ruby infrastructure.

But there's a third type of fundable entity that is a little trickier to put
your finger on. What happens when there's a project that doesn't have any formal
governance structure? Who's in charge then? Really, who _owns_ that project? I
would argue that for every open source project, there is at least one person or
entity who owns that project. I think a fair definition of an owner for an open
source project is anyone who can remove that project from distribution. So, if I
can close a repo on GitHub and pull the gem from RubyGems.org, then I'm probably
the owner of my project. That doesn't mean, however, that there can't be
hundreds more owners of forks of that project! The ability to fork a project is
an important part of open soure, and every fork of a given project has its own
owner.

And here's the tough part - as an owner of a project, if someone pays you for
the development of that project, it's entirely up to you as to how you
distribute or spend those funds. This can be incredibly difficult, but it's 100%
up to the owner (or owners!) of a project. How this is done can have massive
reprocussions - positive _or_ negative - and just the time that one would need
to spend to decide how to spend these funds might not even make accepting them
worthwhile. Unless your case is very simple (one person receives all funds, like
Mike Perham for Sidekiq Pro/Enterprise), or you have some sort of formal body
making these decisions (like Node.js Foundation), I would argue that accepting
funds for your open source project will most likely end up being a net negative
for a project.

## What we really need

Open source developers need to be paid for their work, but individuals are ill
suited to managing the distribution of that payment. That means we need more
companies letting people contribute to open source as part of their
day-to-day work. Personally, I think the sweet spot of sustainability isn't 5
people working full time on open source, but rather 100 people working 1-2
days a week on company time to help make software better as a large community.
This ensures that people are paid for their time, but also keeps that
compensation in the hands of entities that are well equipped to do such things.
