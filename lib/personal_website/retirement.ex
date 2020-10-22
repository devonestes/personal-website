defmodule PersonalWebsite.Retirement do
  @moduledoc """
  Just calculates if I can retire yet or not.
  """

  @inflation "lib/data/inflation.csv"
             |> File.read!()
             |> String.split("\n", trim: true)
             |> tl()
             |> Enum.map(fn row ->
               row = String.split(row, ",")
               year = row |> hd() |> String.to_integer()
               {avg, _} = row |> List.last() |> Float.parse()
               {year, avg / 100}
             end)

  @returns "lib/data/returns.csv"
           |> File.read!()
           |> String.split("\n", trim: true)
           |> tl()
           |> Enum.map(fn row ->
             [year, returns | _] = String.split(row, ",")
             year = String.to_integer(year)
             {returns, _} = Float.parse(returns)
             {year, returns / 100}
           end)

  @combined @inflation
            |> Enum.zip(@returns)
            |> Enum.map(fn {{year, inflation}, {year, returns}} ->
              {year, inflation, returns}
            end)

  @retirement_end_date elem(Date.new(2075, 5, 13), 1)
  @annual_spending 50_000
  @starting_pension 20_000

  def can_i_retire_yet?(value, today \\ Date.utc_today())

  def can_i_retire_yet?(value, {:ok, today}), do: can_i_retire_yet?(value, today)

  def can_i_retire_yet?(value, today), do: value >= needed_to_retire(today)

  def needed_to_retire(today) do
    years = @retirement_end_date |> Date.diff(today) |> Integer.floor_div(365)
    chunks = Enum.chunk_every(@combined, years, 1, :discard)
    binary_search_amount(chunks, 1, 10_000_000, 10_000_000, 5_000_000)
  end

  defp binary_search_amount(_, _, _, middle, middle), do: middle

  defp binary_search_amount(chunks, lower_bound, upper_bound, _, middle) do
    failure = {middle, upper_bound}
    success = {lower_bound, middle}

    {lower_bound, upper_bound} =
      Enum.reduce_while(chunks, failure, fn chunk, _ ->
        if money_left_at_the_end?(chunk, middle) do
          {:cont, success}
        else
          {:halt, failure}
        end
      end)

    new_middle = Integer.floor_div(lower_bound + upper_bound, 2)
    binary_search_amount(chunks, lower_bound, upper_bound, middle, new_middle)
  end

  defp money_left_at_the_end?(chunk, starting_portfolio) do
    starting = {starting_portfolio, @annual_spending, @starting_pension}

    {portfolio, _, _} =
      chunk
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.reverse()
      |> Enum.reduce(starting, fn {chunk, years_left}, acc ->
        {_, inflation, returns} = chunk
        {portfolio, spending, pension} = acc
        annual_changes(inflation, returns, portfolio, spending, pension, years_left)
      end)

    portfolio > 0
  end

  defp annual_changes(inflation, returns, portfolio, spending, pension, years_left) do
    returns = Float.round(portfolio * returns)
    spending_adjustment = Float.round(spending * inflation)
    pension_adjustment = Float.round(pension * inflation)

    portfolio =
      if years_left < 25 do
        portfolio - spending + pension + returns
      else
        portfolio - spending + returns
      end

    {portfolio, spending + spending_adjustment, pension + pension_adjustment}
  end
end
