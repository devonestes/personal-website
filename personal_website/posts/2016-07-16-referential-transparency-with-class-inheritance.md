---
title: Replacing Inheritance with Composition
tags: Inheritance Composition OOP Refactoring
description: In general I really like composition over inheritance in my Ruby code. Yes, there are times when inheritance is cool, but in my mind if you're going to use inheritance you need to really nail it
date: 2016-07-16 10:18:00
---

In general I really like composition over inheritance in my Ruby code. Yes, there are times when inheritance is cool, but in my mind if you're going to use inheritance you need to _really_ nail it, whereas composition has much more room for error and is easier to adapt when those errors do happen. So, I wanted to show an example today of a kind of code that I recently refactored.

Here's a somewhat condensed and exaggerated example of some patterns in some code that I saw recently at work that I wanted to get rid of.

{% highlight ruby %}
class UpdateObject
  def initialize(params)
    @params = params
  end
  
  def call
    find_object
    update_object
  end
  
  private
  
  attr_reader :params, :object
end



class UpdateObjectA < UpdateObject
  def initialize(params, user_id)
    super(params)
    @user_id = user_id
  end
  
  private
  
  attr_reader :user_id
  
  def find_object
    @object = ObjectA.find(params[:id])
  end
  
  def update_object
    object.attributes = object_attributes
    object.user_id = user_id
    object.save!
  end
  
  def object_attributes
    params.slice(:name, :age, :group)
  end
end



class UpdateObjectB < UpdateObject
  def initialize(params, size)
    super(params)
    @size = size
  end
  
  private
  
  def find_object
    @object = ObjectB.find(params[:id])
  end
  
  def update_object
    object.update(size: size)
  end
end
{% endhighlight %}

Now, that code all works. It'll totally do what we want it to do, and I see the idea that we're trying to get across - we're trying to define a common interface for updating objects, and enforcing that by calling methods in the superclass (`UpdateObject`) that need to be implemented in the subclasses (`UpdateObjectA` and `UpdateObjectB`). My problem with that, though, is that it assumes we've correctly identified a pattern that is consistent - and will __always__ be consistent - across how these objects are updated. If we eventually need to change that interface for one object and _not_ the other, it starts to get tricky. As folks say, our abstractions start to get leaky. I don't know about you, but my ability to see into the future is rather limited, and I typically bet against myself when it comes to that, so when I write code I go for maximum flexibility and maintainability, which is why I wouldn't reach for inheritance here to do that interface definition.

But before I get to the final refactor, I wanted to address a couple specific gripes I have with the code here. First off, our superclass - `UpdateObject` - bothers me. One rule I like to try and adhere to is that I shouldn't have to look outside the file I'm in to get information I need about how a class behaves. In the case of our `UpdateObject` class, there is no definition for `find_object` or `update_object`, and also an `attr_reader` for an `@object` variable that isn't acctually set in that class. What's going on?!

Here's how I'd refactor that class before doing the bigger refactor that I want to do:

{% highlight ruby %}
class UpdateObject
  def initialize(params)
    @params = params
  end
  
  def call
    find_object
    update_object
  end
  
  private
    
  attr_reader :params
  
  def find_object
    raise NotImplementedError, 'Must define this in child class'
  end
  
  def update_object
    raise NotImplementedError, 'Must define this in child class'
  end
  
  def object
    return @object unless @object.nil?
    raise NotImplementedError, 'Must set this variable in child class'
  end
end
{% endhighlight %}

That object is still pretty much non-functional, but at least it tells the user what it needs to do, and it also will raise helpful errors rather than just a `NoMethodError` if you forget to implement the method in the child class. The biggest thing for me, though, is that if someone is reading this file that has no idea about any of the other classes that inherit from it, they won't be so confused.

But that leads us towards the end goal that I had, which was to replace that inheritace with composition. So, let's do that now! Let's start off with our `UpdateObject` class.

If we look at it, our `UpdateObject` class itself didn't actually use the `params` that we were passing to it. We just wanted to say that every object that needs to be updated needs params - but I disagree! That's overly prescriptive and doesn't give us flexibilty to change things later on. I think our `UpdateObject` class can be simpler:

{% highlight ruby %}
class UpdateObject
  def initialize(collaborator)
    @collaborator = collaborator
  end
  
  def call
    collaborator.find_object
    collaborator.update_object
  end
end
{% endhighlight %}

To me, that's super clear what is going on, and the class is actually functional. It does stuff that we can test, whereas before we couldn't actually test our `UpdateObject` class - we could only test the subclasses of that class. Also, it still sets a common interface that we want to have for our objects to be updated - but with more flexibility. For example, if we needed to add some sort of action to do after the object is updated, but only some of those objects needed it, we could do something like this:

{% highlight ruby %}
class UpdateObject
  def initialize(collaborator)
    @collaborator = collaborator
  end
  
  def call
    collaborator.find_object
    collaborator.update_object
    if collaborator.respond_to?(:reset_associated_objects)
      collaborator.reset_associated_objects
    end
  end
end
{% endhighlight %}

But in there we have these `collaborator` objects - what would they look like? Here's an example of one:

{% highlight ruby %}
class ObjectACollaborator
  def initialize(params, user_id)
    @params = params
    @user_id = user_id
  end
  
  def find_object
    @object = ObjectA.find(params[:id])
  end
  
  def update_object
    object.attributes = object_attributes
    object.user_id = user_id
    object.save!
  end
  
  private
  
  attr_reader :params, :object, :user_id
    
  def object_attributes
    params.slice(:name, :age, :group)
  end
end
{% endhighlight %}

That object also has a clear set of behaviors that are all testable, and we can in fact create a shared example group for all of these so that we're sure that they implement the methods they need. But we can also easily test the behavior of this object specifically, and there is no need for the tight coupling that we had with the inheritance.

So, that's the refactoring! Personally I think this is a HUGE win, but don't think that I'm totally against inheritance! In face, I have another post coming up soon where I show a refactoring I did that extracted a superclass and added inheritance - but I'll also explain why that was the right choice in that (rare) case.
