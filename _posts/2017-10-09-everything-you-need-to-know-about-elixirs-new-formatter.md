---
title: Everything you need to know about Elixir's new formatter 
tags: Elixir Formatter 1.6 
description: It's been a big weekend! The new formatter that José mentioned in his ElixirConf talk is finally here! It landed on Sunday, and that means we can now poke around
date: 2017-10-09 00:18:00
---

It's been a big weekend! The new formatter that José mentioned in his ElixirConf
talk is finally here! It landed on Sunday, and that means we can now poke around
in the code to see everything that it does and answer a few burning questions.

## Getting started

So, if you want to use it now, you can! You need to clone the repo from GitHub
first with `git clone https://github.com/elixir-lang/elixir.git`. Once you have
the repo cloned to your machine, you can use the beauty of Makefiles to easily
compile and install Elixir. It's a safe bet to first run `make clean test`. Once
all the tests pass on your environment, then you can run `make install`. Once
you do that, you can run `elixir -v` and you should see your version listed as
`Elixir 1.6.0-dev (9b5af3303)` (although maybe with a different SHA).

Now you're ready to start formatting!

## The mix task

Let's start by just formatting a single file. If you're in a normal mix project,
you can run the formatter with `mix format mix.exs`. The third argument there is
the file that you want to format. The mix task will format just that single file
for you.

What if you want to format all the files in your project at once? Easy enough!
You'll need to tell `mix format` where to look, and what files to format. So,
you can run it like this: `mix format mix.exs "lib/**/*.{ex,exs}" "test/**/*.{ex,exs}"`
You can give `mix format` any number of files or patterns of files to format for
you.

Always running it that way is kind of a bummer though, right? There's got to be
a better way - and there is! You can configure the formatter to know which files
to format automatically. This is accomplished with a `.formatter.exs` file. That
file looks something like this:

{% highlight elixir %}
[
  inputs: [
    "lib/**/*.{ex,exs}",
    "test/**/*.{ex,exs}",
    "mix.exs"
  ]
]
{% endhighlight %}

That's a basic file that will make sure all `.ex` or `.exs` files are formatted
every time you run `mix format` without an argument.

You want more formatting options you say? Well, you got it!

If you have macros in your application that you _really_ don't want using
parentheses, you can configure that in your `.formatter.exs` file like so:

{% highlight elixir %}
[
  inputs: [
    "lib/**/*.{ex,exs}",
    "test/**/*.{ex,exs}",
    "mix.exs"
    ],
  locals_without_parens: [
    my_macro: 2,
    my_other_macro: 3
  ]
]
{% endhighlight %}

In that case, it won't enforce the parentheses rule for those macro calls. In
that keyword list you have the macro name as the key, and the arity as the
value.

## Integration into CI

The Core Team really has thought of everything. If you want to make sure that
your CI fails if someone has checked in code that hasn't been properly
formatted, you can add the following to your CI tasks:

```
mix format --check-formatted --dry-run
```

Now, the formatter is probably going to change as bugs are found and as
different versions of it float around out there, so it might not be a great idea
to hook this up now, but for future versions that's one way you'd do it.

## Integration with vim

I use vim, so that's what I'm going to cover here. Below is a nice little
snippet of code that you can drop in your `.vimrc` if you want your code
formatted on save:

```
autocmd BufWritePost *.exs silent :!mix format %
autocmd BufWritePost *.ex silent :!mix format %
```

It also really helps if you have `set autoread` enabled. I'm sure someone will
make a much better vim integration that uses neomake or something to run this in
the background, but for now that will get the job done!
