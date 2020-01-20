---
title: Writing (and testing) a custom Credo check
tags: Elixir Credo Testing ExUnit
description: I've previously written about why one might want to write custom Credo checks, but I didn't talk about the way I actually like to go about doing it in that post, so today I'm going to break down my workflow for writing custom Credo checks.
date: 2020-1-20 00:18:00
---

I've [previously written](/writing-custom-credo-checks) about why one might want to write custom
Credo checks, but I didn't talk about the way I actually like to go about doing it in that post,
so today I'm going to break down my workflow for writing custom Credo checks. A really important
part of this is the testing, and luckily there is an awesome way you can easily test these checks
which really helps with the development as well.

## The tests

Credo provides some lovely functions that can be used for testing checks. The basic setup for all
my tests of custom Credo checks looks like this:

{% highlight elixir %}
defmodule MyCheck.ConsistentFunctionDefinitionsTest do
  use Assertions.Case, async: true

  def "tests for consistently defined functions" do
    """
    defmodule App.File do
      def test(%{}), do: :ok

      def test(_) do
        :err
      end

      def test(other) do
        :other
      end
    end
    """
    |> Credo.SourceFile.parse("lib/app/file.ex")
    |> MyCheck.ConsistentFunctionDefinitions.run([])
    |> assert_issues([
      %Credo.Issue{
        category: :readability,
        filename: "lib/app/file.ex",
        line_no: 4,
        message: "Inconsistent function definition found"
      },
      %Credo.Issue{
        category: :readability,
        filename: "lib/app/file.ex",
        line_no: 8,
        message: "Inconsistent function definition found"
      }
    ])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :filename, :line_no, :message])
    end)
  end
end
{% endhighlight %}

Let's break that down a little bit.

We start with a heredoc that is the source code of the "file" we're looking to parse and check. We
then call `Credo.SourceFile.parse/2` with that source code and a string that represents the path
that file is at (which we're just giving as a random path here because this check doesn't care
about where the file is located).

We then run our custom check on this mocked file, and assert that it returns two `%Credo.Issue{}`
structs. I'm using some helpers there from my testing library
[Assertions](https://hexdocs.pm/assertions/Assertions.html) to make the tests a bit nicer there.

This way, I can run really simple tests on mocked source files, and if I need to do any inspection
of parsed ASTs or anything I can do that super easily.

## The check

Now that I have a test that will help me develop my check, I start off with the basics of a custom
Credo check.

{% highlight elixir %}
defmodule Nicene.ConsistentFunctionDefinitions do
  @moduledoc """
  Function definitions should use one or the other style, not a mix of the two.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability, exit_status: 1

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    []
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Inconsistent function definition found",
      line_no: line_no
    )
  end
end
{% endhighlight %}

This gives me the `run/2` function I need, and `use`s `Credo.Check`, saying that this check is a
readability check, with high priority and a default exit_status of 1. `run/2` needs to return a
list of `%Credo.Issue{}` structs. We also have that `issue_for/2` function that will create those
`%Credo.Issue{}` structs for us, which needs the `issue_meta` returned from `IssueMeta.for/2`, so
that's all set up. Now we can replace that empty list with the actual check implementation.

For this check I first need a list of all the functions defined in this module, and to get that
I'm going to walk the AST and look for function definitions. There's a convenient Credo helper for
that as well!

{% highlight elixir %}
defmodule Nicene.ConsistentFunctionDefinitions do
  @moduledoc """
  Function definitions should use one or the other style, not a mix of the two.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability, exit_status: 1

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    funs = Credo.Code.prewalk(source_file, &get_funs/2, %{})

    []
  end

  defp get_funs(
         {op, _, [{:when, _, [{name, [{:line, line_no} | _], _} | _]} | _]} = ast,
         functions
       )
       when op in [:def, :defp] do
    {ast, Map.put(functions, line_no, name)}
  end

  defp get_funs({op, _, [{name, [{:line, line_no} | _], _} | _]} = ast, functions)
       when op in [:def, :defp] do
    {ast, Map.put(functions, line_no, name)}
  end

  defp get_funs(ast, functions) do
    {ast, functions}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Inconsistent function definition found",
      line_no: line_no
    )
  end
end
{% endhighlight %}

`Credo.Code.prewalk/3` is essentially the same as `Enum.reduce/2`, and lets us recursively go
through all nodes in the AST, and if we hit a node that matches the pattern we're looking for
(which is above - that's what a function definition looks like in the AST) and keep track of
stuff. In this case, we're keeping track of the line number on which a function is defined, and
the name of the function that's been defined.

Now that we have our map of line numbers and function names, we can go through and check the
definitions of those to make sure they're all using the same function definition syntax. This
time, since syntax matters, we're going to iterate over the lines of the actual source file and
not the AST. And what do you know - Credo gives us a helpful function for that as well!
do you know - Credo provides another helpful function for that!

{% highlight elixir %}
defmodule Nicene.ConsistentFunctionDefinitions do
  @moduledoc """
  Function definitions should use one or the other style, not a mix of the two.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability, exit_status: 1

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    funs = Credo.Code.prewalk(source_file, &get_funs/2, %{})

    source_file
    |> SourceFile.lines()
    |> Enum.reduce(%{}, &process_line(&1, &2, funs))
    |> Enum.reduce([], &process_fun(&1, &2, issue_meta))
  end

  defp get_funs(
         {op, _, [{:when, _, [{name, [{:line, line_no} | _], _} | _]} | _]} = ast,
         functions
       )
       when op in [:def, :defp] do
    {ast, [{name, line_no} | functions]}
  end

  defp get_funs({op, _, [{name, [{:line, line_no} | _], _} | _]} = ast, functions)
       when op in [:def, :defp] do
    {ast, [{name, line_no} | functions]}
  end

  defp get_funs(ast, functions) do
    {ast, functions}
  end

  defp process_line({line_no, line}, acc, funs) when :erlang.is_map_key(line_no, funs) do
    def_type =
      if Regex.match?(~r/defp? #{funs[line_no]}.*\),(\z)|( do: .*)/, line) do
        :single_line
      else
        :multiline
      end

    Map.update(acc, funs[line_no], [{line_no, def_type}], &[{line_no, def_type} | &1])
  end

  defp process_line(_, acc, _) do
    acc
  end

  defp process_fun({_, [{_, def_type} | definitions]}, issues, issue_meta) do
    Enum.reduce(definitions, issues, fn
      {_, ^def_type}, acc -> acc
      {line_no, _}, acc -> [issue_for(issue_meta, line_no) | acc]
    end)
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Inconsistent function definition found",
      line_no: line_no
    )
  end
end
{% endhighlight %}

`Credo.SourceFile.lines/1` gives us a list of all lines in the file, along with its line number.
We then iterate through each of those lines, and if it's a line that we know we defined a function
on (because we had it in our previous walkthrough of the AST), we check and see if we're using the
single line syntax or the multiline syntax. We add that to a list of the function definitions for
that given function, and move on.

Once we've done that and we know the syntax used for each function definition, we check the
different function definitions for each function and see if they are all the same or not. If
they're not, we create a new issue.

And voila - we've got a passing test and so we've finished our check!

Yes, this check could be implemented in a simpler fashion, but then I wouldn't be able to show all
the great stuff at our disposal for writing custom Credo checks. Basically, with
`Credo.Code.prewalk/3`, `SourceFile.lines/1`, `Enum.map/2` and `Enum.reduce/3` you can write like
95% of all custom Credo checks you might dream up. The consistency checks are another, more
difficult matter, but I haven't ever heard of a team writing one of those on their own, so there
isn't much need to cover that stuff for now.
