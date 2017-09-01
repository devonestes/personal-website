---
title: Insurance
tags: Refactoring Design OOP
description: I come from America. It's a beautiful, but dangerous, place. We have all sorts of terrible natural disasters that can strike at any moment, and without warning. Hurricaines, tornados, earthquakes, wildfires, volcanos, tsunamis, blizzards,
date: 2017-09-01 00:18:00
---

I come from America. It's a beautiful, but dangerous, place. We have all sorts of
terrible natural disasters that can strike at any moment, and without warning.
Hurricaines, tornados, earthquakes, wildfires, volcanos, tsunamis, blizzards,
avalanches, [killer meteors](https://en.wikipedia.org/wiki/Chesapeake_Bay_impact_crater#Formation_and_aftermath) - Nature seems to really have it out for us!

So, we do what any reasonable person would do and we buy insurance. This
insurance protects us from the uncertainty of the future, knowing that these
things are not only possible, but likely, to happen _eventually_. And, almost
more importantly, it makes us feel safe. We know that if any of these terrible
things were to happen, we would be taken care of. For many kinds of insurance,
this is really what you're paying for.

> If we introduce this layer of abstraction, then we can switch out our data
> access layer at any time and we're ok. If we need to move from ActiveRecord to
> ROM, then we're set. Or if we go from Postgres to MongoDB, it won't matter. We
> won't be coupled to our database at all!

Whether we recognize it or not, we buy insurance all the time when we're writing
our applications. The catestrophic event that will probably happen
in the future is that someone is going to ask us to write more code. This is an
absolute disaster, and we must prepare for it in the best way possible - well
factored code!

Pretty much everything we call "good OO design" is intended to make it easier to
change code. Every design pattern, the SOLID principles, all of it. And so we
create more abstractions, decouple every part of our system, shore up our
inheritance heirarchies - maybe even move to microservices - and wait for that
dreaded moment when we have to do something.

And then the thing we're asked to do is actually kind of easy. We would have
been fine without that additional complexity and those additional layers of
abstraction. For sure, though, the next time we touch this code we're going to
be really happy we have all this flexibility!

But then a couple more features pass, and those abstractions start to just get
in the way. The code was written with the best of intentions, and follows all
the SOLID principles so it _must_ be good code, but all that additional
abstraction comes at a cost. **This is the price we pay for the insurance of
premature abstraction.**

So what's an honest developer to do? Just wait for disaster to strike and be
caught unprepared?! Well, the big difference between nature and software
development is that we often have some idea of what's coming up in the short
term in software. If we have a feature coming up that would be much easier to
implement if there was some additional abstraction in our code, we can make that
abstraction _first_, and _then_ implement the feature.

In the real world if there's a tornado bearing down on your house, you can't
call up and get insurance for the impending disaster. In software, you can. **You
don't need the insurance.** Take advantage of this fact to avoid premature
complexity and make changes only at the last minute. Hold on to simplicity until
something rips it from your hand. Fight valliently against abstraction until it
finally begs to be there. We don't need existing abstractions to feel good
about our code - we should instead rely on our faith in our ability to make
abstractions when needed to feel prepared for any disaster that might come
our way.

> For each desired change, make the change easy (warning: this may be hard),
> then make the easy change. - [Kent Beck](https://twitter.com/kentbeck/status/250733358307500032?lang=en)
