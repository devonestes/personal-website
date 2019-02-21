---
title: Soft delete with Ecto 3 and Postgres
tags: Elixir Ecto 3 Postgres
description: One thing that folks sometimes want or need to do is to be able to "soft delete" records in a database. This means that instead of actually removing the record from a database, you in some way keep it there but make it "invisible" to your application.
date: 2019-2-21 00:18:00
---

One thing that folks sometimes want or need to do is to be able to "soft delete"
records in a database. This means that instead of actually removing the record
from a database, you in some way keep it there but make it "invisible" to your
application.

There are many different ways of doing this, but I've recently settled on the
way I think I'm going to do it from now on when I have applications on Ecto 3
and using Postgres. I've put together a little [example application](https://github.com/devonestes/soft_delete_example)
to show how it works, and that's what I'm going to walk through today.

## The basic plan

The simplist way of describing how this works is that on every table we add a
`deleted_at` column. If that column is null then the record has not been
deleted. If that column has a timestamp in it, then that record has been soft
deleted. We're going to configure our application so that by default it only
"sees" records that have not been soft deleted, but if we want we can see all
records, including those that have been soft deleted. We can also "hard delete"
records if we want to, which will fully remove that record from the database.

## Two "schema"s

There are two things that are called "schema"s that we'll be talking about here,
so before we move on let's describe them and give them better names.

First off, Postgres has a concept of a schema, which relates to essentially a
namespace for a group of relations. By default, all relations are created in the
`"public"` schema, but you can create other schemas with the [`CREATE SCHEMA schema_name`](https://www.postgresql.org/docs/current/sql-createschema.html)
command. So, you can do `CREATE SCHEMA filtered` to have a new `filtered` schema
available where you can create relations. After you create those relations, you
can query from them like `SELECT * from public.users` or `SELECT * from
filtered.users`.

From now on, when we're talking about this schema, we'll always call it a
Postgres schema.

The second schema is the one that we use in Ecto. You've probably seen the code
`use Ecto.Schema` before - that's what we're talking about. A module that
`use`es `Ecto.Schema` we're going to call an Ecto schema.

## The tests

Ok, so let's look at some specifics!

[Here are the tests](https://github.com/devonestes/soft_delete_example/blob/master/test/soft_delete/users_test.exs)
that show how this works. You'll see at this level it looks just like any other
normal test - nothing strange going on here. We just have some well named
functions in a module called `SoftDelete.Users` that do just what they say they
do - creating, retrieving, updating and deleting users. But there are some extra
functions there that are specific to soft delete, like
`list_deleted_users`, `get_deleted_user`, `undelete_user` and
`hard_delete_user`.

## The queries

Now, let's look at that `Users` module to see what's going on there.

Most of these functions look just the same as any other normal application
without soft delete functionality, which is the goal here. The first thing you
might notice that's different as we scan down that file is the implementation
for `delete_user`. In that, if the deletion is successful, instead of returning
the record that was deleted, we actually have to look up another record and
return that instead. A little deviation there, but not too bad.

Then we get to those special functions that deal with the soft deleted users. In
order to access our soft deleted users, we use the
[`prefix`](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-prefix) option in
[`Ecto.Query.from/2`](https://hexdocs.pm/ecto/Ecto.Query.html#from/2). This is
where the real magic happens! This `prefix` corresponds to the Postgres schema
to make our query in. So, when we look at the implementation for
`list_deleted_users`, we see that we're telling Ecto to return all users in the
`public.users` relation.

So if soft deleted users are in the `"public"` Postgres schema, where are the
other users?

## The Ecto schema

The [Ecto schema definition](https://github.com/devonestes/soft_delete_example/blob/master/lib/soft_delete/user.ex)
for our `User` looks just the same as in any other application. We're defining
the fields on our object, and we have two changeset functions - nothing
interesting to see here.

However, instead of `use Ecto.Schema`, we see `use SoftDelete.Schema`, so let's
check in there to see what's going on.

And [in that file, on line
11](https://github.com/devonestes/soft_delete_example/blob/master/lib/soft_delete/schema.ex#L11),
we see the important annotation! We're setting that Ecto schema's
`@schema_prefix` to be `"filtered"`. This tells Ecto that, unless we tell it
otherwise, all operations for this Ecto schema are to be performed against the
`filtered.users` relation instead of `public.users`, which is the default.

So, now we know that in `filtered.users` we have all of the users that haven't
been soft deleted, but in `public.users` we have all users, including those that
have been soft deleted. So, where does `filtered.users` come from?

## The migration

In [the migration that creates our `users` table](https://github.com/devonestes/soft_delete_example/blob/master/priv/repo/migrations/20190220085246_add_users.exs),
we first see what looks like a totally normal `create table(:users)` call. And
indeed it _is_ a totally normal call! But, after that, we get something a
little special. We're executing some custom SQL, so on the `up` part of the
migration we're calling `PERFORM prepare_table_for_soft_delete('users');`, and
on the `down` part of the migration we're calling `PERFORM
reverse_table_soft_delete('users');`. That must be doing something important, so
let's see what's going on there.

## The really important part

So [the first migration in this app](https://github.com/devonestes/soft_delete_example/blob/master/priv/repo/migrations/20190220084718_add_soft_delete_stuff.exs)
is where all the really important and interesting stuff happens.

So much SQL, though! Ughhh, how will I ever understand this?!

Let's start from the beginning and take it step by step.

On [line 9](https://github.com/devonestes/soft_delete_example/blob/master/priv/repo/migrations/20190220084718_add_soft_delete_stuff.exs#L9)
we use `CREATE SCHEMA filtered`, like I mentioned above. This creates a Postgres
schema called `filtered` for us. Easy enough, right?

[The next chunk of SQL on lines 11-21](https://github.com/devonestes/soft_delete_example/blob/master/priv/repo/migrations/20190220084718_add_soft_delete_stuff.exs#L11-L21)
do the most important thing in this app - actually soft deleting our records
instead of deleting them. Here we're creating a Postgres trigger, which is just
a function that's executed after a certain event happens. This particular
trigger says basically "After a record has been deleted, re-insert it back into
the table it came from and set its `deleted_at` field to be the current
timestamp". There are Reasons™ why that has to be an `AFTER DELETE` trigger
instead of a `BEFORE DELETE` trigger, but they're not too important, really, so
I'll spare you from having to read all of them.

Then, [the next chunk of SQL on lines 23-34](https://github.com/devonestes/soft_delete_example/blob/master/priv/repo/migrations/20190220084718_add_soft_delete_stuff.exs#L23-L34)
create that `prepare_table_for_soft_delete` function that we saw in the previous
migration. This function accepts a single argument, which is supposed to be the
name of a table that you've created, and then does four things:

1) Add a `deleted_at` field to the given table
2) Create an index on that `deleted_at` field, because it's going to be used a
_lot_ for queries
3) Set the trigger that we created on lines 11-21 to be active on that table
4) Create a Postgres view in the `filtered` Postgres schema with the same name
as the given table, but that only returns records that haven't been soft deleted.

Once that function has been called, a newly created table has everything it
needs to be used in our application and have soft deleted records!

Finally, [the chunk of SQL on lines
36-47](https://github.com/devonestes/soft_delete_example/blob/master/priv/repo/migrations/20190220084718_add_soft_delete_stuff.exs#L36-L47)
gives us the `reverse_table_soft_delete` function that just undoes the four
things listed above.

## The Repo

By now we've covered just about everything in the app, but the one thing that I
didn't show is how we actually handle hard deletes for when we _really_ want a
record to be removed from the database for good. That's defined in a new
function that we added to [the `Repo`](https://github.com/devonestes/soft_delete_example/blob/master/lib/soft_delete/repo.ex)
called `hard_delete`.

The great thing about this method of handling soft delete is it minimally
affects how Ecto works, and you can see that by looking at that Repo. It's
totally normal with the exception of that one additional function, and that
function itself is fairly normal as well.

What's going on in `soft_delete/1` is we have an `Ecto.Multi` operation, and the
first thing we do is to disable the Postgres trigger that we set to do soft
deletes for us. Once that's disabled, we actually delete the record as we
normally would, and once that's done we re-enable the trigger again so we go
back to defaulting all delete operations to be soft deletes. And yes, this
disabling of the trigger is local to the transaction that the `Multi` is run in,
so you don't need to worry about messing with a form of global state there and
accidentally deleting records you meant to soft delete because of a race
condition!

## Conclusion

So, that's it! Not too scary, right? It's a great soft delete implementation
that you barely see any evidence of in your actual application, works 100% with
all normal Ecto behavior, and doesn't require much in the way of hacky SQL to
make work.

Yes, there are performance tradeoffs here, but that's just the nature of the
beast with soft deletes. If performance becomes an issue for you there are many
ways you can refine this to make it faster, but this shouldn't add more than a
millisecond or two to most operations.
