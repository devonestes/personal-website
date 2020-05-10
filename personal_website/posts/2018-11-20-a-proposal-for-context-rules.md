---
title: A Proposal for Some New Rules for Phoenix Contexts
tags: Elixir Phoenix 1.4 Contexts
description: I like rules. Decision making is way easier when there are rules there to guide you, and I like my decisions to be easy to make. Sure, sometimes we break the rules when we're writing software, and that's ok.
date: 2018-11-20 00:18:00
---

I like rules. Decision making is way easier when there are rules there to guide
you, and I like my decisions to be easy to make. Sure, sometimes we break the
rules when we're writing software, and that's ok. Sometimes the rules themselves
aren't that good, and in that case it's cool to throw them out all together and
create some new rules based on what you learned from the failings of the old
rules. But I find having rules - even arbitrary rules! - really helpful when I'm
programming. Rules keep me from being overwhelmed by [Analysis
Paralysis](https://en.wikipedia.org/wiki/Analysis_paralysis), and that's a very
good thing.

So, today, I'm going to propose a set of rules for structuring Phoenix apps on
versions 1.3 or higher that's a little different from what's explained in the
Phoenix guides on contexts. Specifically I'll be talking about how to structure
your contexts in an application using Ecto.

If you like these rules, try them out! I haven't tried them out in a large
production application, though, so I can't say for sure what issues might crop
up with them down the road. However, I do feel that on a theoretical level I
think these rules are solid and should hold up. If you follow these rules, you
should end up with lots of small functions that can easily be composed together,
and this is a _very_ good thing to strive for.

But really, this is really just a proposal to get these ideas out into the
community and hopefully spark some debate. Until there's emperical evidence that
these rules actually work then they're not worth all that much (which will
frankly never happen), but maybe, if we all talk about them, we can come up
with better rules.

Ok, let's begin!

## 1) Resources have Schema files, and those contain **only** schema definitions, type definitions, validations and changeset functions

Let's take a sort of social media aggragator as our example app for today.
Each "resource" that has an Ecto schema gets it's own Schema file. In that file,
you define that schema, any changesets that you might need to generate, and any
validations you might need to do on that resource. These are the _only_ things
that go in this file, and this file is the _only_ place those things should go.
No random changeset generation in Secondary Contexts (we'll talk about those
later), and no validations in controllers or things like that. Every public
function in this module should return an `%Ecto.Changeset{}` struct.

An example might look like:

```
defmodule MyApp.SocialMedia.Users.User do
  @moduledoc """
  A user that has social media posts
  """

  use MyApp.Schema
  import Ecto.Changeset
  alias MyApp.SocialMedia.{FacebookPosts.FacebookPost, TwitterPosts.TwitterPost}

  @type t :: %__MODULE__{
          id: integer,
          email: String.t(),
          facebook_posts: [FacebookPost.t()],
          twitter_posts: [TwitterPost.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @required_fields ~w(email)a

  schema "users" do
    field(:email, :string)
    has_many(:facebook_posts, FacebookPost)
    has_many(:twitter_posts, TwitterPost)
    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
```

In a simple app this doesn't seem like much, but in production applications this
behavior alone can reach a couple hundred lines of code, so I think it's smart
to restrict this file to only this behavior, and to group all this behavior
together solely in this file.

However, this module should remain _private_ in the sense that you do not test
it directly. You should only test behavior in this module through it's
corresponding Secondary Context.

## 2) Every Schema has its own Secondary Context

Phoenix 1.3 introduced the idea of Contexts, which I'm generally very much in
favor of. However, I wish there was a little bit more structure to the idea.
It's so open ended that I've found deciding where best to put a function kind of
tricky, and then I frequently end up with duplicate behavior across contexts or
have a hard time finding functions later on because the module they're in made
sense at the time, but it doesn't make as much sense now.

So, I'm proposing the idea of a Primary Context and a Secondary Context. First,
let's cover the Secondary Context.

As mentioned in rule #1, every resource (as long as it has an Ecto schema, it
doesn't necessarily have to be backed by a DB) gets it's on Schema file. Well,
every Schema should get it's own Secondary Context. In this module we do all
CRUD operations on that resource, and that's it. Every function in this module
should return either a corresponding resource, a list of corresponding
resources, or a changeset (or list of changesets) for a corresponding resource
in the case of errors.

You'll notice above that we named our resource `MyApp.SocialMedia.Users.User` -
the corresponding Secondary Context for that resource will be named
`MyApp.SocialMedia.Users`, and it might look something like this:

```
defmodule MyApp.SocialMedia.Users do
  @moduledoc """
  Secondary Context for our users
  """

  alias MyApp.{Repo, SocialMedia.Users.User}

  def find(id), do: Repo.get(User, id)

  def find_and_load_associations(id) do
    id
    |> find()
    |> load_twitter_posts()
    |> load_facebook_posts()
  end

  def create(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  def load_twitter_posts(user) do
    Repo.preload(user, :twitter_posts)
  end

  def load_facebook_posts(user) do
    Repo.preload(user, :facebook_posts)
  end
end
```

Again, in this silly example this might not seem like a lot, but in production
applications this becomes a pretty large amount of code sometimes. You will
probably end up with lots of small functions, and that's totally ok! If we have
lots of small functions, that's how we end up with great buildling blocks for
composition later on.

## 3) The **only** place you use your Repos is in a Secondary Context, and only for the associated resource

All interacitons with your Repos must be done through the Secondary Contexts. This
means no randomly preloading associations in controllers or using `Repo.get/3`
in a view or something. If you see a Repo used anywhere outside of a Secondary
Context, then add a function that does the thing you want to the Secondary
Context instead.

Also, within a Secondary Context, do not reach across boundaries to another
resource directly. For example, the following would be disallowed under these
rules:

```
defmodule MyApp.SocialMedia.Users do
  # ...

  def user_for_facebook_post(post) do
    Repo.preload(post, :user).user
  end
end
```

Even though we're using the Repo in a Secondary Context and we're returning a
`User` struct, both of which are allowed, we're passing a `FacebookPost` struct
to the repo in the `Users` Secondary Context, which is bad. Instead, we should go
through that resource's Secondary Context if we want to access that data, like so:

```
defmodule MyApp.SocialMedia.Users do
  # ...

  def user_for_facebook_post(post) do
    FacebookPosts.with_user(post).user
  end
end
```

Calling functions in one Secondary Context from a different Secondary Context is
allowed, although you should be careful about how you define dependencies
between Secondary Contexts. In reality, the above function really doesn't belong
in a Secondary Context at all, since it's about the relationship between two
different resources. It should really be in a Primary Context.

## 4) Primary Contexts define higher level ideas in your application, and most interactions between resources will take place there

So we have basic CRUD operations for each resource defined in the Primary
Context for that resource, but then we need to think about the bigger picture.
This is really what Phoenix Contexts were originally designed for, but I found
the mixing of basic CRUD operations for resources and functions related to the
larger picture defined in that context kind of tricky to maintain over time. I
also found the mixing of Schema functionality and the CRUD functionality that
I'm putting in Secondary Contexts to be too much for a single module, which is why
I extracted out that idea of a Secondary Context.

So, it will frequently happen that our Primary Context will call many
functions from our Secondary Contexts, and compose those together to form
higher-level functionality. Here's an example:

```
defmodule MyApp.SocialMedia do
  @moduledoc """
  Functions for dealing with social media posts and post authors
  """

  # ...

  def author_of(%_{user: %User{} = user}), do: {:ok, user}
  def author_of(%FacebookPost{} = post), do: {:ok ,FacebookPosts.with_user(post).user}
  def author_of(%TwitterPost{} = post), do: {:ok, TwitterPosts.with_user(post).user}
  def author_of(_), do: {:error, "No author available for this post"}

  def all_posts_for(user) do
    user =
      user
      |> Users.load_twitter_posts()
      |> Users.load_facebook_posts()

    user.twitter_posts ++ user.facebook_posts
  end

  def download_all_posts_for(user) do
    user
    |> APIs.Twitter.download_posts_for(user)
    |> TwitterPosts.bulk_create(user)

    user
    |> APIs.Facebook.download_posts_for(user)
    |> FacebookPosts.bulk_create(user)
  end
end
```

This is where, in my propsal here, the real context boundary takes place.
Nothing outside of this Primary Context should call any of the functions in any
Secondary Contexts within that Primary Context - and I do view the relationship
between Primary and Secondary Contexts as a "container" - to the rest of the
application, those Secondary Contexts (and their associated Schemas) are totally
invisible.

I think of the Primary Context, Secondary Context and Schema as three individual
layers of privacy, basically. A Primary Context can call functions in any
Secondary Context, but not from any Schemas. Secondary Contexts can call any
functions in the Schema for its associated resource, but not for sibling
resources.

At each level we're making a clean abstraction, and this (for me at least)
makes it much easier to decide how to structure my code.

I also find that this structure makes it much easier to move a resource
_between_ contexts when the time comes to do so. It's almost never the case
that, when we set out to design an application, we get it all right up front.
There is learning to be done in the process of development, and when that
happens we need to refactor. When we already have a layer of abstraction between
our Primary Context and Secondary Contexts, refactoring is much easier to do
later on.

## One last note

As you may have noticed, what we have here is essentially a dependency (or file
system, if you want to think of it that way) tree. The directory tree for the
above example might look like this:

```
.
├── social_media.ex
└── social_media
    ├── users.ex
    ├── users
    │   └── user.ex
    ├── facebook_posts.ex
    ├── facebook_posts
    │   └── facebook_post.ex
    ├── twitter_posts.ex
    └── twitter_posts
        └── twitter_post.ex
```

And the great thing about trees is that they're a highly recursive data
structure. Trees are made of sub-trees. So, in theory, there's nothing stopping
you from one day composing Primary Contexts together into some form of Super
Context or something that further encapsulates some other, even larger idea! I
haven't really tried this out, but this seems like a really reasonable way
(to me) to work on an application.

In fact, that's sort of how this idea came about. I was working on an
application, and the higher level boundaries weren't very clear to me at first,
so as I was developing I started with just Secondary Contexts - no Primary
Contexts at all. As the context boundaries started becoming clearer, I
defined those abstractions as Primary Contexts that then became the sole
interface for all that functionality.

How far this composition of smaller units of abstraction into larger units goes
I don't really know, but I'm pretty interested in finding out one day!
