---
title: Software nihilism
tags: academics 
description: I've been doing a lot of reading of academic research papers recently. Mostly to support some claims I'm hoping to make in an upcoming conference talk, but also just because I think it's important to read the actual research out there (when there is any!). It's left me in a bit of a funk, though. Specifically, a paper called "Measuring Refactoring Benefits: A Survey of the Evidence" by Counsell, Yamashita & Cinnéide has left me feeling particularly disheartened.
date: 2017-04-08 10:18:00
---
I've been doing a lot of reading of academic research papers recently. Mostly to support some claims I'm hoping to make in an upcoming conference talk, but also just because I think it's important to read the actual research out there (when there is any!). It's left me in a bit of a funk, though. Specifically, a paper called "Measuring Refactoring Benefits: A Survey of the Evidence" by Counsell, Yamashita & Cinnéide has left me feeling particularly disheartened.

I love refactoring. It makes me feel good in the same way it feels good to go to the gym - you're doing something good for yourself. But the summation of their meta-anlysis of the existing empirical research on the benefits of refactoring sort of hit me hard.

> "In summary, a significant number of works attempt to evaluate the impact of refactoring on various aspects of code quality, but in general the results fail to show a clear link between refactoring and either a reduction in code smells or an improvement in overall quality."

What a bummer! I fought hard to institute a practice called Refactor Fridays at my current job to give us every other Friday to just refactor and clean stuff up. I thought it was a worthwhile endeavor, and it still _felt_ like something really worthwhile, too. It's not just refactoring as a whole that seems to have little effect on the quality of software. Duplicate code, long though of as a key source of bugs and long-term software issues, seems to not really be a problem at all, and maybe even a _feature_ in our codebases! From a study by a group of researchers at Osaka University titled "An Empirical Study on the Impact of Duplicate Code" comes this quote:

> "In this study, we found that duplicate code tends to be (more) stable than nonduplicate code."

The thought that went through my head after reading all this is "Oh, ok, so nothing matters and our software will always be terrible. Great." I've searched for other studies that could maybe offer some different methodology to find better results, but I haven't been able to find anything. Finding this stuff is a huge problem, but the biggest problem in general is the fact that there is so little research out there to begin with.

So, what do we believe? Should we continue with our eminance based science instead of evidence based science? For example, because Dave Thomas is a very smart man with lots of exeperience, then he knows better than anyone what's good, and we should listen to him? I don't think we can, since two of the sacred cows of software, supported by our most eminent leaders, seem to actually not really be all that holy.

I also don't think it's reasonable to expect more research on these topics to be done. There isn't glory in telling people they're doing it wrong. People want answers and new things to do - not just lists of things that don't work. Additionally, these experiments are exceptionally hard to do. They require expensive, highly trained people and lots of time to replicate the real world. Analyzing open source developement is probably the closest that we can get to real world parity, but that's still incredibly different than real commercial software development.

So, given that, it looks like we need to just take a deep breath, acknowledge that we're all doing our best, and follow our hearts. We'll most likely never really be "sure" that we're doing the "best" thing for our codebase. But, in the end, maybe it all just doesn't matter - and that's ok. It's also kind of heartening to know that, for the most part, I can't really write "bad" software, since our previous definitions of bad don't really hold up!
