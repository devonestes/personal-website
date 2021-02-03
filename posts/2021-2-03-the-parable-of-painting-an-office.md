---
title: The Parable of Painting an Office
tags: Engineering Management Estimates
description: Today I'm taking a bit of a different track on what I'm writing about. Instead of something very technical, I'm going to talk about something completely non-technical - estimation. Estimation is one of those things that everybody wants, but nobody ever really gets, and this is something that can be really hard to explain to product folks, but I've used this example to explain our faults in estimation quite a lot, and so I wanted to actually write it down and share it with folks in case they could use it as well.
date: 2021-2-03 01:01:01
---

Today I'm taking a bit of a different track on what I'm writing about. Instead of
something very technical, I'm going to talk about something completely non-technical - estimation.
Estimation is one of those things that everybody wants, but nobody ever really gets, and this is
something that can be really hard to explain to product folks, but I've used this example to
explain our faults in estimation quite a lot, and so I wanted to actually write it down and share
it with folks in case they could use it as well.

Below is a bit of a parable that I tell, and in it, we have to imagine that I'm talking to _you_
directly, and it's up to you to answer the questions that I ask. When I ask a question below,
really take some time to try and think about the best and most correct answer that you can give!
(Fair warning - many of these questions are sort of trick questions, but that is to make the point
of the parable).

## How long will it take to paint my office?

This is my office.

![Picture of my office](/images/my_office.jpg)

It's not a big office - just about 250cm by 350cm (that's 8 feet by 11.5 feet for non-metric
folks) - but I really like it. It's nice to have a place to do my work in peace. But I don't like
the color of the paint, and so I'd like you to paint it. I'm thinking something just a touch
warmer, like #FFFED6.

Ok, so now you know the color I want and the the size of the office. This should be enough for you
to be able to estimate how long it'll take to paint the office, right? I mean, most people
generally know how a paint brush works, and so I think you should be able to give a pretty
accurate estimate of how long it will take to paint - so what's your estimate (in hours) for how
long it will take? Really think about it, and maybe even write this number down.

Got your number? Great - let's move on.

So it's the day you said you'd start painting, and you show up to paint the office. Did you
remember to buy and bring all the paint supplies? Did you just assume that I'd have done all of
that for you? No way! You're the painter, so **you** need to buy the paint and brushes and tape
and floor covers and such. That's why I told you the color I wanted! So, if you didn't include the
time it would take to buy supplies, estimate how long that will take and add that time to your
original estimate now.

Ok, so now you've got supplies and are ready to paint! Well, actually, you're not really ready to
paint yet - first you need to move all that furniture in the picture above away from the walls,
right? You can't just paint over the desk and the shelves! And of course I want **you** to do
this - that's why I hired a painter! So if you didn't include this time to move the furniture away
from the walls, you can estimate how long that will take and add it to your original estimate now.

Great, so now the walls are clear, and you need to tape off all the edges of the baseboards and
put down plastic so paint doesn't splatter on the floor and such. Did you remember that time in
your estimate? If not, add that now!

And so you're ready to actually apply paint! You paint all the walls, but did you paint the
ceiling? Of course I want the ceiling done - that would look weird otherwise! If you didn't
include the time to paint the ceiling in your original estimate, add that time in now.

After you've painted the ceiling you're done, right? Think again! You need to apply two coats of
paint so the color looks good. Which means you now need to wait for the first coat of paint to
dry, and then paint all 4 walls and the ceiling again. If you didn't include this in your original
estimate, add this extra time in now.

Ok, so now you're done and my office looks really beautiful! Thank you so much!

## The moral of the story

When we set out to estimate how long something will take, we never do this in enough detail to be
accurate. And even if we try really, **really** hard, we'll _still_ get it wrong. Maybe our
estimates for how long any given piece of work will take are themselves incorrect, but what
happens far more often, and with a far greater impact on the time it takes to actually deliver a
piece of work, is that we miss entire steps in the process that we didn't know that we needed to
do. If something as simple as painting an office can have so many possible things that we forget
to do when we're estimating, just imagine how many things can come up when trying to change a
giant, highly interconnected software system like most modern web applications!

The theory that we hear most often is that if we break work down into small enough pieces then
we'll be less likely to miss steps in any given process, and this is indeed correct. But "small
enough" is generally way smaller than most people give it credit for, and even then there are
still lots of ways that estimation can go wrong. This is better, but still not really reliable.

And so when it comes to the dangerous game of estimation in software projects, we can look to the
imaginary AI in the classic 1983 film _War Games_ to learn our lesson:

> The only winning move is not to play.
