---
title: My New Favorite Elixir Testing Trick 
tags: Elixir TDD Testing
description: When I write my Ruby tests, I'm a big fan of using test doubles and asserting those doubles receive messages with the correct arguments. I guess I like to practice what Justin Searls calls Discovery Testing
date: 2017-07-13 10:18:00
---

When I write my Ruby tests, I'm a big fan of using test doubles and asserting
those doubles receive messages with the correct arguments. I guess I like to
practice what Justin Searls calls [Discovery Testing](https://github.com/testdouble/contributing-tests/wiki/Discovery-Testing).

One thing I've really enjoyed about Elixir is how easy it is to test, but I've
also sort of missed the isolation that you get by using test doubles. Well,
lucky for me, I've now seen what I think might be an even _better_ version of that
pattern, and it's great for testing the edges of your application where you have
to deal with the gnarly outside world (like IO).

I've been doing a big refactor on [Benchee](https://github.com/PragTob/benchee)
recently, and while working on that I ran across the following test:

```
test "asks to print what is currently benchmarking" do
  test_suite()
  |> benchmark("Something", fn -> :timer.sleep 10 end)
  |> measure(TestPrinter)

  assert_receive {:benchmarking, "Something"}
end
```

I thought "Woah, that looks just like an assertion on an object receiving a
message in Ruby! What black magic is happening here?" Well, of course it wasn't
black magic, but the closest thing we have to it in Elixir - OTP!

So, the secret lies in that `TestPrinter` module that we're passing to the
`measure/2` function. In the actual code we're passing in a [`Printer`](https://github.com/PragTob/benchee/blob/master/lib/benchee/output/benchmark_printer.ex) module
which has functions involved with printing stuff to the console. Of course we
want to ensure that this code is executed in our tests, but we don't actually
want to print to the console the whole time. Also, exactly _what_ is printed
isn't really the scope of this test, so using `capture_io` and doing some RegEx
magic on it to make sure stuff is printed would be duplicating test behavior.

So, instead we have this wonderful module:


```
defmodule Benchee.Test.FakeBenchmarkPrinter do
  def duplicate_benchmark_warning(name) do
    send self(), {:duplicate, name}
  end

  def configuration_information(_) do
    send self(), :configuration_information
  end

  def benchmarking(name, _) do
    send self(), {:benchmarking, name}
  end

  def fast_warning do
    send self(), :fast_warning
  end

  def input_information(name, _config) do
    send self(), {:input_information, name}
  end
end
```

What that module does is replicate the same interface as the actual `Printer`
module, but instead of writing to the console, it sends messages to the current
process running that test. Then we can use the built in `assert_receive`
function in ExUnit to assert that the current process received a message
matching what we put in our `FakeBenchmarkPrinter` module. I've seen a few other
examples of dependency injection in tests in Elixir that allow you to test a
given function in isolation - I've even [written about a similar thing](/refactoring-for-tests-in-elixir) before -
but this was the first time I'd seen anything like this.

Pretty cool,huh? I can't take credit for this, though - props to
[Tobias Pfeiffer](http://www.pragtob.info/) for this one!
