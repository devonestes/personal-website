---
title: Refactoring for Tests in Elixir 
tags: refactoring Elixir Testing
description: I've been turning something over in my mind recently, so I'm going to try and write down some of these thoughts to get some clarity around my thinking here. Now that my talks are over for a while, I'm able to dive back 
date: 2017-05-25 10:18:00
---

I've been turning something over in my mind recently, so I'm going to try and write down some of these thoughts to get some clarity around my thinking here. Now that my talks are over for a while, I'm able to dive back into some open source work (YAY!), and specifically I wanted to contribute back to [Benchee](https://github.com/PragTob/benchee), the wonderful Elixir benchmarking tool. I tackled a new feature to add some cross-platform system information to the UI output, and in [working on that feature](https://github.com/PragTob/benchee/commit/6bf18013e746ce2211f765059956dda03721650f) some interesting questions came up.

First off, testing private functions. Coming from Ruby, I never tested private functions. However, when we have code like the below, it makes me wonder if maybe we should!

```
def cpu_speed, do: cpu_speed(os())

defp cpu_speed(:Windows) do
  parse_cpu_for(:Windows, system_cmd("WMIC", ["CPU", "GET", "NAME"]))
end
defp cpu_speed(:macOS) do
  parse_cpu_for(:macOS, system_cmd("sysctl", ["-n", "machdep.cpu.brand_string"]))
end
defp cpu_speed(:Linux) do
  parse_cpu_for(:Linux, system_cmd("cat", ["/proc/cpuinfo"]))
end

defp parse_cpu_for(_, "N/A"), do: "N/A"
defp parse_cpu_for(:Windows, raw_output) do
  "Name" <> cpu_info = raw_output
  String.trim(cpu_info)
end
defp parse_cpu_for(:macOS, raw_output), do: String.trim(raw_output)
defp parse_cpu_for(:Linux, raw_output) do
  ["model name\t:" <> cpu_info] = Regex.run(~r/model name.*:[\w \(\)\-\@\.]*ghz/i, raw_output)
  String.trim(cpu_info)
end
```

Having pattern matching means that I can very easily test each branch of the logic involved in this part of the application in isolation. This is awesome - or is it?! Are private functions implementation details that shouldn't be tested like they are in OOP, or are they just a way to limit your "interface"? Because of the nature of what we're testing (system information), we can't test the public function unless we test on macOS, Linux and Windows separately.

I ended up settling on not testing these private methods. First off, I _do_ think they're implementation details, and they don't describe the public behavior of the application, so they shouldn't be tested. If they're tested for development, then those tests should be deleted before deployment. But the real calculus that I made was that the benefit from having those tests didn't outweight the cost of keeping those tests around.

The next issue that I had here was that we're having to test code that deals with the unpredictable outside world - specifically, we need to make system calls on all three platforms and then handle those system calls. Tobias had the great recommendation of pulling all this into a single function so we can keep our error handling in one place. But, how do we test this? 

```
defp system_cmd(cmd, args) do
  {output, exit_code} = System.cmd(cmd, args)
  if exit_code > 0 do
    IO.puts("Something went wrong trying to get system information:")
    IO.puts(output)
    "N/A"
  else
    output
  end
end
```

Because that `System.cmd/2` call relies on the system on which the code is run, we can't control the output of that function. That means we can't test the error handling without forcing the machine to fail somehow in a predictable way - and that's tricky.

So, now I was thinking of two possible solutions:

1) Make this function pbulic and extract the reference to `System.cmd/2` out as an argument to this function so we can pass in a test double for that function that consistently behaves in the way we expect, or:

2) Extract the `if/else` statement in that function into pattern matching, and test each branch individually.

Here's what option 1 would look like:

```
def system_cmd(cmd, args, system_func \\ &System.cmd/2) do
  {output, exit_code} = system_func.(cmd, args)
  if exit_code > 0 do
    IO.puts("Something went wrong trying to get system information:")
    IO.puts(output)
    "N/A"
  else
    output
  end
end
```

And here's what option 2 would look like:

```
defp system_cmd(cmd, args) do
  cmd |> System.cmd(args) |> handle_errors
end
def handle_errors({output, 0}), do: output
def handle_errors({output, _}) do
  IO.puts("Something went wrong trying to get system information:")
  IO.puts(output)
  "N/A"
end
```

After considering both options, I ended up [going with option number 1](https://github.com/PragTob/benchee/pull/88). My thinking here was two fold. First off, I liked the "readability" of having all the logic in one function. It wasn't too much logic, and it (to me) makes it easier to see the flow of control when using `if/else` instead of pattern matching here. Second, though, I felt that just testing the handling of errors alone, and not unit testing `system_cmd/2`, was a little odd. Maybe that's a feeling that I'm still applying inaccurately from my OO experience, but to be honest, that's why I went with that decision.

And of course, in the end, both are perfectly valid and there isn't really a "correct" answer here ;)
