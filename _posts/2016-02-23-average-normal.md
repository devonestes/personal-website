---
title: Average != Normal
tags: Statistics Performance
description: One of my biggest pet peeves is when I hear weather reports saying something like 'It's 20 degrees above normal today'. I've lived in New York, Pittsburgh, San Francisco and now Berlin, and I feel like only one of
date: 2016-02-23 10:18:00
---

One of my biggest pet peeves is when I hear weather reports saying something like 'It's 20 degrees above normal today'. I've lived in New York, Pittsburgh, San Francisco and now Berlin, and I feel like only one of those four cities could have any claim towards an idea of 'normal' weather. If for a given week in Berlin the temperature was exactly the same as the average temperature for that day, I would honestly think someone was controlling the weather! What's normal in Berlin is wide swings in temperature - really, a bell curve with pretty fat tails and a low peak. In the parlance of finance and statistics, what's normal in Berlin is a [Platykurtic](http://www.investopedia.com/terms/p/platykurtic.asp) distribution of temperatures, and what's normal in San Franciso is  [Leptokurtic](http://www.investopedia.com/terms/l/leptokurtic.asp) distribution. So when reporters say something is 'abnormal', they're making a big mistake.

![distributions](/assets/images/kurtosis.jpg)

Any single event, as long as it's possible, isn't necessarily abnormal, but the real issue is the definition of 'normal'. Depending on how narrow our set of data that we're drawing a definition of 'normal' from is, just about anything could be abnormal. For example, if I notice that between noon and 6pm the sun is shining brightly in the sky, then the setting of the sun is abnormal. That's never happened before in the set of data that I'm using to define normal. The larger the set of data we use to define 'normal', the closer we'll get to truly finding what is and is not in or out of the realm of possibility for any given situation.

This has been on my mind for a couple reasons - first and foremost because I keep hearing people complaining about 'abnormal' weather, but also because I've been thinking a lot recently about application performance. These two things aren't at all related, but what is related is the concept of normal.

If I were to ask you what 'normal' behavior is for your app, would would you say? What about if I asked you specifically what a 'normal' number of application errors per day was, or a 'normal' page load time, or a 'normal' amount of traffic? You will most likely look at the average numbers for all of these questions, but that's _incredibly_ misleading. I was listening to an older podcast with Yehuda Katz, and he made the super valid point that this is a terrible way of looking at website performance. His company's product, [Skylight](https://www.skylight.io/), takes a much better look at application performance, and I'd encourage you to take a look at it. Here's a version of the example they give:

Let's say 50% of your response times were around 50ms, 30% were around 100ms, and the remaining 20% were north of 1000ms. You'd look at your average and say your response time was 255ms. That's not terrible, but it hides the fact that a whole 20% of your customers are waiting a full second for something to happen on the page! So, the average in this case is NOT normal - 50% of your responses are 5 times faster than the average, and 20% of your responses are 4 times slower than average.

So, when you're looking at application performance, don't forget that an average isn't enough when you're looking for answers. Look for the patterns, and strive to make your application as leptokurtic as possible!
