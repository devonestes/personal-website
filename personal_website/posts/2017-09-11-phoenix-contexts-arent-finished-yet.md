---
title: Phoenix contexts aren't finished yet 
tags: Elixir Phoenix Context DDD Testing 
description: I recently migrated a Phoenix app from 1.2 to 1.3, including introducing some contexts. I like the concept in general, but I think the current implementation (from the few examples I've seen, and from the examples in the official documentation) isn't quite finished yet.
date: 2017-09-11 00:18:00
---

> Phoenix projects are structured like Elixir and any other Elixir project – we
split our code into contexts. A context will group related functionality,
such as posts and comments, often encapsulating patterns such as data access
and data validation. By using contexts, we decouple and isolate our systems
into manageable, independent parts.
- [the Phoenix guides](https://hexdocs.pm/phoenix/contexts.html#thinking-about-design)

I recently migrated a Phoenix app from 1.2 to 1.3, including introducing some
contexts. I like the concept in general, but I think the current implementation
(from the few examples I've seen, and from the examples in the official
documentation) isn't quite finished yet. I firmly believe in the stated goal,
which I've pulled from the documentation above. Decoupling and isolating parts
of our system is awesome! But, with contexts as they stand now, that decoupling
is only uni-directional.

## Our example app

Let's go with the example in the documentation to keep consistent. 

```
defmodule HelloWeb.UserController do
  use HelloWeb, :controller

  alias Hello.Accounts
  alias Hello.Accounts.User

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  ...
end
```

Now, let's look at this example a little deeper. The stated goal of these
contexts is to keep the parts of our larger system decoupled and independent.
And one of the parts of our system is our web layer, so the router,
controllers, views and templates.

When I'm thinking of how decoupled two parts of a system are, the heuristic I
frequently use is "how easy is it for me to replace one part with another
thing". That frequently takes the form of using some sort of test double or
"mock" in testing. If it's really decoupled, I should be able to test that
part using entirely fake data.

Let's examine that controller a bit more, and specifically let's look at how we'd
test that it. Can we test it without having to insert records into our database?
Can we easily switch out the data access layer of our application in order to
use fake data?

**No, we cannot.**

![context dependencies](/assets/images/dependencies.png)

If I want to test a given controller action, I am actually coupled to the
implementation of the `Accounts` module. I cannot test this piece of my system
in isolation. Sure, our actual controller isn't coupled, but the _tests_ for
that controller sure are!

We can, however, test our data access and business logic in isolation without
any reference to the web layer of our application. This is great! And the more
we can break our business logic down into further independent contexts, the
better! **It's just not yet true that _all_ of our contexts are equally
independent.**

## Good and Bad dependencies

```
that picture above are ok - I might even go so far as to say they're encouraged!

We are all dependent on data in each and every one of our functions. If we
expect something to be a `String.t` and we instead get an `integer`, then our
code will most likely blow up. That's ok! So, given that this dependency on data
is the natural order of things, being very explicit about the data on which we
are dependent is great. That's why I think it's actually a really great thing
that we're dependent here on specifically the `%User{}` struct and the
`%Ecto.Changeset{}` struct. We're clear as to what our functions need.

There are also dependencies on a larger level. If you have a Phoenix
application, and you want to use Ecto to manage your data access, you'll be
dependent on that library. That's again not only ok, but it's great! Now you
don't need to write your own buggy version of a library to manage database
access.

And even the mild form of dependency that we have in our controller is actually
pretty darn good! We're insulated from many different types of implementation
details, and only in testing do we really see the extent of the coupling between
these contexts. So, what can do we here?

## Solutions

We've identified that controllers in Phoenix 1.3 are essentially the
point of integration between the web layer of your application and any other
contexts that you might be using. How can we try and reduce that coupling even
further?

#### Idea 1 - Configuration

The dependency that we really want to remove here is on the `Accounts` module.
So, let's see if we can do that by configuring our application to use a
different module for testing!

We could update our controller to look like this:

```
defmodule HelloWeb.UserController do
  use HelloWeb, :controller

  @accounts_module Application.get_env(:hello, :accounts_module)

  alias Hello.Accounts.User

  def index(conn, _params) do
    users = @accounts_module.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = @accounts_module.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case @accounts_module.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  ...
end
```

We could then add some configuration to `config/test.exs`

```
config :hello, :accounts_module, Hello.FakeAccounts
```

And then in our `config/prod.exs` and `config/dev.exs` we could add:


```
config :hello, :accounts_module, Hello.Accounts
```

This would allow us to use a fake implementation of that behavior when testing
this part of application in isolation. The downside is it would probably end up
being a lot of configuration for any application of non-trivial complexity.


#### Idea 2 - Default arguments 

If we want a way to switch out that `Accounts` module for testing, but we don't
want to spend hours configuring our applications, we could also do that
switching by passing that module in as an argument to our controller function.
To make it so development and production function just like they always have, we
could rely on a default argument.

Let's update our controller and see what that might look like:

```
defmodule HelloWeb.UserController do
  use HelloWeb, :controller

  alias Hello.Accounts
  alias Hello.Accounts.User

  def index(conn, _params, accounts_module \\ Accounts) do
    users = accounts_module.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params, accounts_module \\ Accounts) do
    changeset = accounts_module.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}, accounts_module \\ Accounts) do
    case accounts_module.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  ...
end
```

I think this is preferable to the configuration option, but with one major
downside - it means we need to test our controllers in a very specific way. Most
controller tests I've seen look something like this:

```
defmodule HelloWeb.UserControllerTest do
  ...
  test "index returns a list of users", %{conn: conn} do
    conn = get(conn, "/users")
    assert conn.status == 200
  end
  ...
end
```

Nowhere in there are we explicitly _calling_ the function that we would need to
call in order to pass in that fake module. We would need to edit that test to
look like this:

```
defmodule HelloWeb.UserControllerTest do
  ...
  test "index returns a list of users", %{conn: conn} do
    conn = HelloWeb.UserController.index(conn, %{}, FakeAccounts)
    assert conn.status == 200
  end
  ...
end
```

Personally I could argue that this is actually preferable to the established
norm, but I generally value following the established norm over doing what I
think is right, so I wouldn't really want to deviate from that here.

#### Idea 3 - A change in perspective

The whole reason this is a problem for me is because of my understanding of
contexts and the documentation around them. In all that documentation, it says
that essentially the web layer is a context like any other, and that they should
all behave the same way. We've seen that this isn't true, but what if we just
accepted the special status of the web layer?

What if, instead of presenting the web layer as just another context, we
presented it instead as a sort of superset of all your other contexts, plus some
additional behavior? Every other part of your application might be independent and small,
but your web layer will depend on those other contexts explicitly, and there will
be tight dependencies at that point. If we wanted to pull all the other contexts
out into individual applications, we'd be just fine, but we can't do that with
our web layer - at least, not as it stands now.

There's nothing wrong with that, other than it kind of brings us back to the
whole ["Phoenix is not your application"](https://www.youtube.com/watch?v=lDKCSheBc-8) argument. 
Personally, for now, this is the approach I'm going to take. I'd be really
interested to see how this idea develops in the future, though!
