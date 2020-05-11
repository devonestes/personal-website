---
title: Implementing Elixir's Pipeline in Ruby
tags: Elixir Ruby FP Pipeline 
description: I've been really loving Elixir, and one of the things I've loved the most is the pipeline operator |>. You see it in cases like this
date: 2016-05-16 10:18:00
---

I've been really loving Elixir, and one of the things I've loved the most is the pipeline operator `|>`. You see it in cases like this:

```
1..100_000
  |> Stream.map(&(&1 * 3))
  |> Stream.filter(odd?)
  |> Enum.sum
```

Basically what it does is pass the return value from a previous function or expression as the first argument in the next function. Pretty cool, huh?

I've been finding that there are some functional paradigms that have been really helpful in increasing the testibility and reducing the complexity of my Ruby code, and as a sort of experiment I wanted to see if I could implement this operator in Ruby!

Before I get into my actual implementation, I want to say that what I came up with is a terrible idea. It involves monkey patching the `Object` class, and that is just asking for weird behavior in any app of significant size or complexity. So, __DON'T DO THIS!__ But, hopefully this thought experiment will get you thinking about other ways in which functional paradigms might help you write better OO code.

#### First Lesson - Ruby doesn't like `def |>`
I should have expected this, but when I try and define a method `|>`, the Ruby interpreter has some issues with me.

```
irb(main):001:0> def |>
irb(main):002:1* puts 'PIPING'
irb(main):003:1> end
SyntaxError: (irb):1: syntax error, unexpected '>', expecting ';' or '\n'
(irb):3: syntax error, unexpected keyword_end, expecting end-of-input
	from /Users/devoncestes/.rbenv/versions/2.2.3/bin/irb:11:in `<main>'
irb(main):004:0>
```

If we can't use the actual `|>` operator, I decided to just use a method called `pipeline`. There's already a `pipe` method defined in `IO` (which came as no surprise), but `pipeline` isn't yet defined as an instance method in the Ruby standard library or in Ruby Core, so I figured I'd go with that. It's defined as a class method in the `Open3` module, but I didn't think that my implementation would clash too bad.

#### The implementation

So, here's what I ended up with. It's actually much simpler than I had imagined, but I don't yet have _all_ of the functionality of Elixir's pipeline operator included in here. It's kind of a middleground at the moment, but it does rely on passing around functions, which is really what I wanted to get at here.

```
class Object
  def pipeline(*args)
    func = args.shift
    if func.is_a?(Proc) || func.is_a?(Method)
      func.call(self, *args)
    elsif func.is_a?(UnboundMethod)
      func.bind(self).call(*args)
    else
      raise NotImplementedError, "Function type not implemented yet"
    end
  end
end
```

For a less stupid way of implementing this behavior, you could have the following module that you include in whichever classes you want to have this kind of functional behavior like so:

```
module Pipeable
  def pipeline(*args)
    #... Same implementation as above
  end
end

class String
  include Pipeable
end
```

What this allows us to do is create `Proc`, `Method` or `UnboundMethod` objects, and then chain them together, passing around a certain piece of data and doing some sort of transformation on it as we define in our function. Here are a couple of examples:

```
power_level = 'nine thousand'
func1 = String.instance_method(:upcase)
func2 = Proc.new { |str| "His power level - it's over #{str}!!" }
func3 = method(:puts)
power_level
  .pipeline(func1)
  .pipeline(func2)
  .pipeline(func3)
# => "His power level - it's over NINE THOUSAND!!"
```

I really wish I could write that as:

```
power_level
  |> func1
  |> func2
  |> func3
```
but I have a feeling the minute I start doing custom patches to the Ruby interpreter then I'm going to get into some real trouble, so I'm just going to live with what I have a the moment!

Why did I choose to have `Proc`s, `Method`s and `UnboundMethod`s as the methods that we're passing around? Well, it seems like Ruby has already settled on that as the main way that functions are passed around. There's lots of use `to_proc` calls when you use the symbol to proc syntax (i.e. `array.reduce(:+)`), and in the last year or so I've seen a lot more usage of the `&method` helper to generate an `Method` object. And `UnboundMethod` just seems cool, so I threw that in for good measure.

So, there ya go! Now of course chainable methods are nothing new in Ruby, but I think there is an important distinction between this and the way many of them are frequently implemented. Most of the time when you see chains of methods you're thinking about stuff using the `Enumerable` module, and that's really designed to operate on collections of data like arrays and hashes. This `pipeline` method is much more generic, without any sort of implicit ideas of enumerating over a collection of objects.
