---
title: Unit Tests in Elixir - Part 2
tags: Elixir ExUnit Testing Tests Unit
description: In part 1 of this series I went over a couple rules that I follow when writing unit tests. Now I'm going to dig in to some of the specifics of how to unit test certain types of behavior that can be a little tricky to do properly.
date: 2018-11-02 00:18:00
---

In [part 1](/unit-tests-in-elixir-part-1) of this series I went over a couple
rules that I follow when writing unit tests. Now I'm going to dig in to some of
the specifics of how to unit test certain types of behavior that can be a
little tricky to do properly. In part 1 I said that unit tests test all
functionality **within** a single process. But then how can we unit test
something that talks to another process?

For today let's work on unit testing the functions in the `Persist` module in
the following code:

```
defmodule KVStore do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def write(key, value) do
    GenServer.cast(__MODULE__, {:write, key, value})
  end

  def read(key) do
    GenServer.call(__MODULE__, {:read, key})
  end

  def handle_cast({:write, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end

  def handle_call({:read, key}, _, state) do
    {:reply, Map.get(state, key), state}
  end
end

defmodule Persist do
  def write_all(params) when is_map(params) do
    Enum.each(params, fn {k, v} -> KVStore.write(key, value) end)
  end

  def read_all(keys) when is_list(keys) do
    Enum.map(keys, &KVStore.read/1)
  end
end
```

Now all of those functions in `Persist` send messages to a GenServer. How can we
unit test them when all their functionality depends on inter-process
communication? Well, we get rid of the inter-process communication.

As the code is now in `Persist`, the only way we could remove the inter-process
communication is to have some sort of configurable adapter in `KVStore`. But
that would be weird, and still pretty hard to test (although in some cases that
adapter pattern does work well, but not here).

So, we need a seam in which we can inject our dependencies, and in the case of
testing, we can use a mock (or test double, which are pretty much the same
thing). The way I like to do that is with default arguments, like so:

```
defmodule Persist do
  def write_all(params, kvstore \\ KVStore) when is_map(params) do
    Enum.each(params, fn {k, v} -> kvstore.write(k, v) end)
  end

  def read_all(keys, kvstore \\ KVStore) when is_list(keys) do
    Enum.map(keys, &kvstore.read/1)
  end
end
```

Now that code behaves exactly the same as before, but we also have a seam into
which we can inject our dependency as an argument to a function. Yes, it's a
little unwieldy having a default argument at the end of every function there. It
isn't as _pretty_. But, it allows us to properly unit test those functions like
so:

```
defmodule PersistTest do
  use ExUnit.Case, async: true

  defmodule KVStore do
    def write(key, value), do: send(self(), {:write, {key, value}})

    def read(key), do: {:read, key}
  end

  describe "write_all/2" do
    test "sends the correct message to our KV store for each key/value pair" do
      Persist.write_all(%{key: :value, key2: :value2} KVStore)
      assert_receive({:write, {:key, :value}})
      assert_receive({:write, {:key2, :value2}})
    end
  end

  describe "read_all/2" do
    test "returns a list of values for the given keys" do
      assert Persist.read([:key, :key2], KVStore) == [{:read, :key}, {:read, :key2}]
    end
  end
end
```

Ok, so what's going on here. First, we can see that we're injecting a new module
as our test double. That test double isn't actually a `GenServer` - it just hard
codes some behavior for us. Also, we see that in our `write/2` function we send a
message to `self()` (which in this case is the process actually running the
test), and in our `read/1` function we're returning values. This is because our
`write/2` function in our actual implementation is a **command**, and the `read/1`
function in our actual implementation is a **query**. These are terms that come
from the object oriented world, but they apply here just as well.

When we send a message to a process and we don't expect a response (so, a `cast`
in GenServer terms), we're sending a command. What that process does with
that message is totally up to it, and what happens based on that command isn't
the responsibility of any other process. It's implementation is a private
concern. That's why we don't test that behavior. We only test that the message
was sent. And in the case of a GenServer with a nice public API, we can do that
by mocking out that API as we've done above. We get notice that the function is
called when we receive the message that we've sent ourselves. This is as far as
this unit test should go - verifiying that the correct function was called with
the correct arguments.

When we send a message to a process and we do expect a response (so, a `call` in
GenServer terms), we're sending a query. In the cases of queries, what is
important is that something is returned, but not necessarily _what_ is returned.
The logic around what gets returned based for a given message should be unit
tested in the `KVStoreTest` module and not here. When you're testing queries,
the only thing you need to verify is that the function is called with the right
argument, and we can do that by asserting against the return value of the
function we're mocking.

So, when you're testing functions that interact with some other process,
remember the three important parts:

* Inject your dependencies as function arguments so you can use a mock/test double
* Test commands by sending messages to `self()`
* Test queries by asserting against return values

Remember those three rules and you should be able to effectively unit test any
function that interacts with another process!
