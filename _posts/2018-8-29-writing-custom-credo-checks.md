---
title: Writing custom Credo checks 
tags: Elixir Credo
description: 
date: 2018-8-29 00:18:00
---

I love automation of things. I especially love automating the simple parts of
code review, since much of that stuff can be easily automated with static
analysis tools. And one of my favorite static analysis tools, Credo, offers the
ability to add your own custom checks if you so desire!

While the standard suite of checks gets you most of the way there, every team
has their own style and things they want to be enforced. This can either be
enforced by a human reading the code and noticing all the times this style isn't
followed (ugh...), or you can have Credo do it for you (yay!).

So, to start writing your own check, Credo has a nice mix task that gives you a
skeleton of a check that you can work with: `mix credo.gen.check`. You invoke it
by giving it a file path in which you want to generate the skeleton of your
check, like `mix credo.gen.check lib/my_first_credo_check.ex`. That skeleton of
a check should walk you through the gist of the process, and you can also look
at the implementations of all the other checks on Credo for help if you need it.
Many checks involve parsing the Elixir AST, so if you're not familiar with that
format, that might be a good thing to read up on before moving into this realm.
I recommend Chris McCord's book Metaprogramming Elixir if you want a good
overview of how the Elixir AST works. The rest of them are just parsing the
actual text of the code, which is usually a little easier to understand but
often relies on some really complicated regular expressions.

Now that you have your check implemented, you can add it to be run by including
it in your `.credo.exs` file under the `checks` key. Pretty easy, right?

It's a really great, and I think under used feature of Credo. A little
automation can go a long way in making code review much easier and keeping a
codebase consistent, and if you're weird like me, writing these static analysis
tools can actually be really fun!

And in case you're thinking of some ideas for custom checks, here you go:

- Some people don't like the `&` syntax for anonymous functions and always want
the full `fn -> end` syntax.
- I've seen teams that don't like to use `with` with only a single clause.
- Some people don't like when pipelines are all on the same line like `data |>
fun1() |> fun2`.
- Some folks don't like bare `_` in patterns and always want `_var_name` for
documentation purposes.

Those are just a few things you can write custom checks for. It might be worth
having a conversation with your team about what style and standards you want to
enforce on your project, and then sitting down to write some checks and saving
everyone code review time and the need for style comments in code review. The
extra special benefit of this is that these style comments, when they come from
an automated source, usually come off as helpful to folks, whereas when a human
brings them up they often come off as pedantic and silly, so these checks can
actually help with team morale as well!
