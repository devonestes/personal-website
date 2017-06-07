---
title: Three APIs for Method Objects in Ruby
tags: APIs Testing Singleton 
date: 2017-03-19 10:18:00
---
####TLDR;
Here are the two APIs that I think make sense for Method Objects in Ruby:

1) Stateful

{% highlight ruby %}
class MultiUseMethodObject
  def initialize(at_least_one_persistant_argument)
    # ...
  end
  
  def call(any_number_of_ephemeral_arguments)
    # ...
  end
end
{% endhighlight %}

2) Stateless

{% highlight ruby %}
class SingleUseMethodObject
  def self.call(any_number_of_ephemeral_arguments)
    new(any_number_of_ephemeral_arguments).call
  end
  
  def initialize(any_number_of_ephemeral_arguments)
    # ...
  end
  
  private
  
  def call
    # ...
  end
end
{% endhighlight %}

I've written (and spoken) before about my love of Method Objects in Ruby, but there's one very important thing I wanted to cover in more depth - the API of a method object. There are three different ones that I see, and I think two of them have really good, clear use cases. Let's start with one that we'll call the Stateful Method Object.

Let's say that we have an API endpoint that we need to hit, and to do that we're going to use a method object like the below:

{% highlight ruby %}
class FirstTenTweetGetter
  def initalize(api_key:)
    @api_key = api_key
  end
  
  def call(username:)
    # Hit your API endpoint here and return some data.
    # This could maybe be something like returning the first
    # 10 tweets from your user's Twitter timeline.
  end
  
  private
  
  attr_reader :api_key
end
{% endhighlight %}

Because your API key isn't going to change from request to request, that object can live on and on, storing that unchanging state. In fact, when you boot up your app, you might want to assign an instance of that object to a constant or global variable (__gasp!__) so you can just refer to that global "function" (since that's essentially what it is) directly.

What we have now is not just a Method Object, but also a Singleton (although not a very strictly enforeced one). You can save yourself from having to initialize a new object every time with the exact same argument. Theoretically this could also help performance and memory usage since you're reusing an object rather than continually allocating, garbage collecting, and then re-allocating essentially the same object. However, the benefit is so small as to be functionally useless.

This is also not too bad when it comes to testing, and more specifically when it comes to unit testing dependent objects. If you're referring to the object directly in a method (i.e., looking it up as that constant or global variable that was created when you booted your app), then you can stub out `#call` on that singleton instance to avoid actually making an API call and return some dummy data.

Even better would be to pass this "ready to use function" into any objects that depend on it so you can pass a test double when you're testing your dependent objects! Both options aren't too much of a bummer to test, although the second is certainly more flexible and would be my choice for sure.

The next type of API is the "Stateless" Method Object. You'll see why the quotes are necessary in a second :)

So, here's our example class:

{% highlight ruby %}
class NumberSaver
  def initialize(num1, num2)
    @num1 = num1
    @num2 = num2
  end
  
  def call
    Number.create(important_number: num1 + num2)
  end
  
  private
  
  attr_reader :num1, :num2
end
{% endhighlight %}

So, the big difference is that in that class there isn't anything that's useful to retain between uses. The numbers that we're given are ephemeral - they only matter for the life of the `call` method and once that's done the whole object can go away and get garbage collected. Why are we setting instance variables at all, you ask? Well, sometimes in the many private methods that are sure to be added to this class, you'll need to work with that data in a significant manner, and in general it's better to set that shared class level state to an instance variable for ease of access and clarity of purpose.

Where this bothers me, though, is in the testing of client objects that use this class. If any of your Method Objects are commands (as in Command/Query commands) like this one is, then the "right" way to test dependent objects is to not test the results of the command, but rather to test that the commands were called and with the proper arguments. To do that with this API requires two expectations, and more stubbing than I think is necessary. Below is an example dependent class and some tests for it:

{% highlight ruby %}
class TextAdder
  def initialize(num1, num2)
    @num1 = num1
    @num2 = num2
  end
  
  def call
    # Let's imagine that there is some far more complicated thing to do
    # rather than just call to_i on our numbers here
    NumberSaver.new(num1.to_i, num2.to_i).call
  end
  
  private
  
  # ...
end
{% endhighlight %}

{% highlight ruby %}
describe TextAdder do
  it 'calls NumberSaver with the correct arguments' do
    instance = double(call: true)
    expect(NumberSaver).to receive(:new).with(2, 2) { instance }
    expect(instance).to receive(:call).with(no_args)
    TextAdder.new('2', '2').call
  end
end
{% endhighlight %}

A particularly bad test for this `TextAdder` class would be one that _also_ tests the `NumberSaver` functionality since it creates unnecessary coupling in our tests and is no longer a unit test but instead now a poor imitation of an integration test. Here is that example:

{% highlight ruby %}
describe TextAdder do
  it 'adds and saves two text numbers' do
    expect(Number.count).to eq 0
    TextAdder.new('2', '2').call
    expect(Number.count).to eq 1
    expect(Number.last.important_number).to eq 4
  end
end
{% endhighlight %}

There's another way to sort of hide the instantiation (since you'll never actually need to reuse any given instance of this class) and to make the API a little more clear (as well as easeir to test), and it's below:

{% highlight ruby %}
class NumberSaver
  def self.call(num1, num2)
    new(num1, num2).call
  end
  
  def initialize(num1, num2)
    @num1 = num1
    @num2 = num2
  end
  
  private
  
  def call
    Number.create(important_number: num1 + num2)
  end
  
  attr_reader :num1, :num2
end
{% endhighlight %}

And now we're back to our Singleton! Our class defintion (which, let's not forget, is an instance of the `Class` class) is our singleton object for this "function". The instantiation of an object in order to do whatever we're asking of that singleton "function" is now just an implementation detail that we don't need to care about. The new "proper" test for our client class looks like this:

{% highlight ruby %}
describe TextAdder do
  it 'calls NumberSaver with the correct arguments' do
    expect(NumberSaver).to receive(:call).with(2, 2)
    TextAdder.new('2', '2').call
  end
end
{% endhighlight %}

But beyond the greater simplicity of properly testing client classes for that class, it's also more descriptive of what we are really dealing with - a stateless, singleton function. Again, passing that function around as an argument would provide greater flexibility and even better testing, but I think I've stretched this contrived example to its limits already!
