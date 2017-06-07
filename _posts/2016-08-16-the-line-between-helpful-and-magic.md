---
title: The Line Between Helpful and Magic 
tags: OOP Registry Inheritance Composition Refactoring
date: 2016-08-16 10:18:00
---

In general I prefer composition over inheritance. However, recently there were a couple bugs around a certain group of objects in our codebase that pointed out a refactoring that was begging to be made, and in this case inheritance was the right way to go. Today I'm going to go over that refactoring and explain it a bit.

Let's start with a short explanation of the problem domain! In our app we have a lot of third party data that we handle. The problem is, much of it is wrong! We spend a lot of time cleaning that data, and to help with that we try and run a bunch of algorithms determine if we feel an object exhibits markers that might make it ripe for cleaning. We call this process Flagging, and it is _very_ important ;)

We have `Flagger` classes that are given an object to flag (note: that's the verb this time) and are responsible for calling all of those methods and then passing on the results to a class to handle updating our database. That class looked something like this:

{% highlight ruby %}
class DistrictFlagger
  FLAGGING_METHODS = %i(paid_too_much paid_too_little no_schools)
  
  def initilize(district_id: district_id,
  			  district: District.find(district_id))
  @district = district
  end
  
  def call
    results = FLAGGING_METHODS.each_with_object({}) do |method, hash|
      hash[method] = public_send(method)
    end
    FlagStatusManager.new(results: results, object: district).call
  end
  
  private
  
  attr_reader :district
  
  def paid_too_much
    Flagging::PaidTooMuch.new(district).call
  end
  
  def paid_too_little
    Flagging::PaidTooLittle.new(district).call
  end
  
  def no_schools
    Flagging::NoSchools.new(district.num_schools).call
  end
end
{% endhighlight %}

So, it's a pretty simple class, right? However, this approach led to bugs! First off, whenever we added a new Flag, we had to remember to touch this class to add it to `FLAGGING_METHODS` and also to add the instantiaion of that object and injection of dependencies so we can call it. Also, as these classes got larger, there was eventually some issue with confusion around naming in each of the `Flagging` method objects, so ideally we wanted to find a way to make that naming consistent, but we'll solve one problem at a time.

So, let's start with addressing the Open/Closed violation that we have going on here. To fix the problem of having to touch the `DistrictFlagger` class every time we add a new flag, we can use the Registry pattern. Now the Registry pattern is generally good, but it comes with the downside of relying on shared global state. Kind of a bummer, but it's the only way to make it work, really. So, here's what one of our flagging classes might look like after we've done that:

{% highlight ruby %}
module Flagging
  class NoSchools
    method_name = self.class.name.gsub('Flagging::', '').underscore
    ::DISTRICT_FLAGS[method_name] == true
    
    attr_reader :num_schools
    
    def initialize(num_schools:)
      @num_schools = num_schools
    end
    
    def call
      # Implementation here...
    end
  end
end
{% endhighlight %}

We're now relying on the presence of a `::DISTRICT_FLAGS` hash to serve as our registry, and each flagging class registers itself in that registry when the code is evaluated.

And then we'd change our `DistrictFlagger`'s `call` method to look like this:

{% highlight ruby %}
class DistrictFlagger
  def call
    results = ::DISTRICT_FLAGS.keys.each_with_object({}) do |method, hash|
      hash[method] = public_send(method)
    end
    FlagStatusManager.new(results: results, object: district).call
  end
end
{% endhighlight %}

So we've removed the need for that `FLAGGING_METHODS` constant in the `DistrictFlagger` class, but we still need to create that method to be called. The problem there, though is, that each class can have different dependencies that we need to inject. Sounds like we're going to have to use some metaprogramming!

Let's change our registration code in our `NoSchools` class.

{% highlight ruby %}
module Flagging
  class NoSchools
    dependencies = [:num_schools]
    ::DISTRICT_FLAGS[self.class.name] == dependencies
    
    attr_reader :num_schools
    
    def initialize(num_schools)
      @num_schools = num_schools
    end
    
    def call
      # Implementation here...
    end
  end
end
{% endhighlight %}

Now in that registry we're registering a class name, as well as the dependencies that the class needs injected when it's instantiated. This is getting better! We can go back to our `DistrictFlagger` class and do some more modification to that `call` method:

{% highlight ruby %}
class DistrictFlagger
  def call
    results = ::DISTRICT_FLAGS.each_with_object({}) do |(klass, dependencies), hash|
      args = dependencies.map(&method(:send))
      result = klass.constantize.new(*args).call
      hash[klass] = result
    end
    FlagStatusManager.new(results: results, object: district).call
  end
end
{% endhighlight %}

That's a little more gnarly, but basically what we're doing is:

1) take the registered dependecies, which correspond to methods implemented in the `DistrictFlagger` class, and map over them to get the values we need to inject to our flagging class
2) instantiate and call that flagging class
3) pass the results on to the `FlagStatusManager`

The real great part about this is now we don't need to define methods in the `DistrictFlagger` to instantiate and call our flagging objects!

We've made it this far without any inheritance (or composition for that matter), but there's one other refactoring that I wanted to do here. If we look in our `NoSchools` class, we're referencing the dependencies (in this case, `num_schools` in a bunch of places. Let's see if we can declare those dependencies once and then have a bunch of other stuff happen for us automatically!

I'm going to skip the middle ground and get right to the solution. In the end, our flagging class looks like this:

{% highlight ruby %}
module Flagging
  class NoSchools < Flag
    dependencies = [:num_schools]
    register ::DISTRICT_FLAGS, dependencies
    
    def call
      # Implementation here...
    end
  end
end
{% endhighlight %}

I think that's a pretty good API for those classes - clear, concicse, and we're only dealing with certain ideas in one place rather than in multiple places.

And here's the base class that we're inheriting from:

{% highlight ruby %}
class Flag
  def self.register(flag_registry, dependencies)
    flag_registry[name] = dependencies

    module_eval <<-INIT
      def initialize(#{dependencies.join(', ')})
        @#{dependencies.join(', @')} = #{dependencies.join(', ')}
      end
    INIT

    attr_reader(*dependencies)
  end
end
{% endhighlight %}

There's some metaprogramming going on there to evalute our `initialize` method and set our instance variables correctly based on our dependencies, and we're also creating `attr_reader` methods for those dependencies as well.

There are a couple reasons I reached for inheritance here. First and foremost, you coudln't really get this behavior with composition. I mean, technically you could, but it would be confusing. Also, in this case _every one_ of our child classes uses _all_ of the behavior of the parent class. Lastly, there are _no_ reverse dependencies (when something in the parent class depends on an implementation in a child class). Those are pretty much my rules for using inheritance, and I've found that it suits me well.

The one issue I have with this final implementation is that I wonder if it's too "magic". Unless you dug into the code for `Flag`, you might not know that the `initialize` method is defined for you. I'm ok keeping it for now, though, because it solved an actual problem we were seeing and it wasn't something that was added because I thought it might be nice to have. Also, after I finished this refactoring I pulled over a couple of our less experienced engineers and asked them if they knew what was going on, and they did! That's usually my test for if my code is too clever - if the engineer with the least experience on the team can figure it out easily, then it's ok. Personally I think that's a great heuristic to go by!
