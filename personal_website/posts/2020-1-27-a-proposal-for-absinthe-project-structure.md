---
title: A proposal for an Absinthe application structure
tags: Elixir Absinthe GraphQL
description: One of the great things about GraphQL is how broad the abstractions are. Everything is just an "object", with "fields"! This makes things infinitely composable, and is where a good deal of the power in GraphQL comes from. But, like all things, there are downsides to this - first and foremost is that it makes organizing a project difficult.
date: 2020-1-27 00:18:00
---

One of the great things about GraphQL is how broad the abstractions are. Everything is just an
"object", with "fields"! This makes things infinitely composable, and is where a good deal of the
power in GraphQL comes from. But, like all things, there are downsides to this - first and
foremost (in my opinion) is that it makes organizing a project difficult. Because you _can_ do
just about anything, you might end up doing that, and having a fairly difficult time of finding
things and knowing where to put stuff. But, most importantly, this can make talking about GraphQL
applications difficult since some of these terms are really murkey.

I've worked on 3 GraphQL projects now, and I think I've settled on the structure and nomenclature
that I really like, and that's what I'm going to present today. But, before I dive into it, we
need to get some terms defined up front. Every time I use one of these terms later on, this is
what I'm referring to.

* **type** - This is the definition of a type (using `object` in Absinthe). These defintions
    usually look something like this:

```
object :user do
  field :id, :id
  field :name, :string
  field :age, :integer
end
```

* **input object** - This is a type, but it's kind of special since it is used to define the
    arguments given to an operation (if any are needed). They look just like objects, but use a
    different macro for definition:

```
input_object :user_input do
  field :name, :string
  field :age, :integer
end
```

* **schema** - the last thing we needed was another thing in our application called a "schema"
    (since database schemas and Ecto schemas already a thing), but here we are. When you're
    talking about these with your team, it's helpful to always say stuff like "Ecto schema" or
    "Absinthe schema" to avoid confusion. These schemas define the interface for our API, and are
    made up of "queries", "mutations" and "subscriptions", but we break them up into chunks for
    certain domain concepts in our application to make them easier to work with, and those usually
    look like this:

```
object :user_queries do
  field :users, list_of(:user) do
    description("A list of all users in the system.")
    resolve(&UserResolver.list/3)
  end
end
```

Ok, so with that out of the way, we're going to use the cannonical blog post example for our
domain today, with `user`s, `post`s and `comment`s.

## The directory structure

First off, this post isn't going to cover much in the `blog` context, as I've already [covered my
thoughts on that stuff](/a-proposal-for-context-rules) before. But, this is what the general
directory structure would look like (minus the normal stuff in every project like config and
such):

```
.
+-- lib
|   +-- blog
|   |   +-- etc...
|   +-- blog_web
|   |   +-- channels
|   |   |   +-- etc...
|   |   +-- types
|   |   |   +-- users.ex
|   |   |   +-- posts.ex
|   |   |   +-- comments.ex
|   |   +-- schemas
|   |   |   +-- mutations
|   |   |   |   +-- user.ex
|   |   |   |   +-- post.ex
|   |   |   |   +-- comment.ex
|   |   |   +-- queries
|   |   |   |   +-- user.ex
|   |   |   |   +-- post.ex
|   |   |   +-- subscriptions
|   |   |   |   +-- post.ex
|   |   +-- resolvers
|   |   |   +-- user_resolver.ex
|   |   |   +-- post_resolver.ex
|   |   |   +-- comment_resolver.ex
|   |   +-- views
|   |   |   +-- etc...
|   |   +-- endpoint.ex
|   |   +-- router.ex
|   |   +-- schema.ex
|   +-- application.ex
|   +-- blog.ex
|   +-- blog_web.ex
+-- test
|   +-- blog
|   |   +-- etc...
|   +-- blog_web
|   |   +-- resolvers
|   |   |   +-- user_resolver_test.exs
|   |   |   +-- post_resolver_test.exs
|   |   |   +-- comment_resolver_test.exs
|   |   +-- schemas
|   |   |   +-- mutations
|   |   |   |   +-- user_test.exs
|   |   |   |   +-- post_test.exs
|   |   |   |   +-- comment_test.exs
|   |   |   +-- queries
|   |   |   |   +-- user_test.exs
|   |   |   |   +-- post_test.exs
|   |   |   +-- subscriptions
|   |   |   |   +-- post_test.exs
+-- README.md
+-- mix.exs
+-- etc...
```

I think the general idea there is pretty clear - we separate `type`s, `resolver`s and `schema`s
into their own directories. Each type should have a corresponding resolver, and if there are
queries, mutations or subscriptions for those types, they belong in their own file. Now, onto
what's in each section!

## Types

In our `types` directory, we have a file for each type - but that file can contain more than one
`type` definition! We also put our input_objects in here, since that's the best place to keep
these sorts of things. For example, in `blog_web/types/user.ex`, we could have something like
this:

```
defmodule BlogWeb.Types.User do
  use Absinthe.Schema.Notation

  object :user do
    field :id, :integer
    field :name, :string
    field :age, :integer
    field :posts, list_of(:post) do
      resolve(&BlogWeb.Resolvers.PostResolver.posts_for_user/3)
    end
  end

  input_object :user_input do
    field :id, :integer
    field :name, :string
    field :age, :integer
  end

  object :admin do
    field :id, :integer
    field :name, :string
    field :age, :integer
    field :posts, list_of(:post)
    field :organization_name, :string do
      resolve(&BlogWeb.Resolvers.UserResolver.admin_organization_name/3)
    end
  end

  input_object :admin_input do
    field :id, :integer
    field :name, :string
    field :organization_name, :string
    field :age, :integer
  end
end
```

These are all of our user-related types, and so we can put them all there. If we needed more
specific objects or input objects related to users, we could also put them here.

What we shouldn't have in here are any actual resolver functions - all definitions for all
resolvers should be in the associated resolver module. No using anonymous functions in here, even
if they're just a couple lines! Keeping things consistent means always using one thing or the
other, and since always using anonymous functions for resolvers wouldn't work at all, never using
them is the only remaining option.

## Schemas

I really wish I had a better word for these things (maybe folks can call them schema fragments?),
but what goes in `blog_web/schemas` are essentially decomposed parts of one large schema, defined
in `blog_web/schema.ex`. So, we chunk that one huge schema up into smaller pieces, and those
pieces look something like this (for example, `blog_web/schemas/queries/user.ex`):

```
defmodule BlogWeb.Schemas.Queries.User do
  use Absinthe.Schema.Notation

  object :user_queries do
    field :user, :user do
      arg :input, non_null(:user_input)
      resolve(&BlogWeb.Resolvers.UserResolver.find/3)
    end

    field :users, list_of(:user) do
      description("A list of all users in the system.")
      resolve(&BlogWeb.Resolvers.UserResolver.list/3)
    end
  end
end
```

In there we've defined our queries relating to users, as well as documentation and resolution
functions for those queries. The same restrictions go for mutations and subscriptions.

Oh, and one other thing - try and make sure that if a query, mutation or subscription need any
arguments that they take a single input, and that input is a previously defined `input_object`,
like we've done above with our `:user_input` above.

Once we have all those bits and pieces, we put it together in a `blog_web/schema.ex` file like so:

```
defmodule BlogWeb.Schema do
  use Absinthe.Schema

  import_types(__MODULE__.Types.{
    Comment,
    Post,
    User
  })

  import_types(__MODULE__.Schemas.Queries.{
    Post,
    User
  })

  query do
    import_fields(:user_queries)
    import_fields(:post_queries)
  end

  import_types(__MODULE__.Schemas.Mutations.{
    Comment,
    Post,
    User
  })

  mutation do
    import_fields(:comment_mutations)
    import_fields(:post_mutations)
    import_fields(:user_mutations)
  end

  import_types(__MODULE__.Schemas.Subscriptions.{
    Post
  })

  subscription do
    import_fields(:post_subscriptions)
  end
end
```

If you're consistent enough with naming and such you could potentially even write a nice little
macro to take care of all that for you, but _please_ don't jump right to that since macros can be
a huge pain to maintain over time.

## Testing

Ok, just really quick on this one. Resolver functions are tested just like any other function, and
those tests look like this (in `test/blog_web/resolvers/user_resolver_test.exs`):

```
defmodule BlogWeb.Resolvers.UserResolverTest do
  use Blog.DataCase, async: true

  alias Blog.Factory

  describe "list/3" do
    test "returns a list of users" do
      users = Factory.insert_list(3, :user)
      assert_lists_equal(users, UserResolver.list(nil, nil, nil))
    end
  end
end
```

Then, our schemas are tested in files that mirror the way they're defined, so we test user queries
in `test/blog_web/schemas/queries/user_test.exs` and comment mutations in
`test/blog_web/schemas/mutations/comment_test.exs`. The describe blocks in those tests are for
each query/mutation/subscription under test, and look like this:

```
defmodule BlogWeb.Schemas.Mutations.CommentTest do
  use Blog.DataCase, async: true

  describe "createComment" do
    test "creates a comment" do
      query = """
      mutation f($input: commentInput!){
        createComment(input: $input) {
          id
          body
          post {
            id
          }
        }
      }
      """
      variables = %{"body" => "I am a comment body.", "postId" => 123}

      assert {:ok, %{data: %{"createComment" => comment}}} =
        Absinthe.run(query, BlogWeb.Schema, context: %{}, variables: variables)

      assert is_integer(comment["id"])
      assert comment["post"]["id"] == 123

      assert %{body: "I am a comment body.", post_id: 123} = Repo.get(Comment, comment["id"])
    end

    test "fails without a post_id" do
      # implementation here
    end
  end

  describe "updateComment" do
    # more tests here
  end
end
```

So, we're testing two things there - the response to our client, **and the side effects!** I've
seen so many times where just the response is tested in these kinds of tests, but the side effects
(usually what happens in the database) aren't tested at all, and that's super dangerous.

Usually one of these tests for the happy path and one test for some sort of expected failure (like
querying for a user that doesn't exist, or an authorization error or something) is enough at this
level, and then you can test more specific cases further down the stack.

## The tradeoffs

The tradeoffs here are that we have a lot of files. Some people don't like having a lot of files,
and instead of having files like `blog_web/schemas/queries/user.ex` and
`blog_web/schemas/mutations/user.ex`, they would just want `blog_web/schemas/user.ex` with all the
schemas for that domain concept in there.

I don't like that because then the corresponding test file would be absolutely massive, and I
think it's worth having the consistency of test files matching source files. Once you end up with
that thing that has like 15 mutations on it (usually `user`, but there's always something), then
you start breaking stuff apart, and you lose the consistency. I'd rather err on the side of
consistency than on the side of conveniences for 95% of cases that don't cover the other 5%.
