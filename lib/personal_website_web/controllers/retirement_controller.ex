defmodule PersonalWebsiteWeb.RetirementController do
  use PersonalWebsiteWeb, :controller

  alias PersonalWebsite.Retirement

  def show(conn, _) do
    [today, at_60, at_65, at_70] =
      [Date.utc_today().year, 2045, 2050, 2055]
      |> Enum.map(&Task.async(fn ->
        {:ok, date} = Date.new(&1, 5, 13)
        Retirement.needed_to_retire(date)
      end))
      |> Enum.map(&Task.await/1)
      |> Enum.map(&format_number/1)

    html = """
    <!DOCTYPE html>
    <html>
      <body>
        <h1>€#{today} needed to retire today.</h1>
        <h1>€#{at_60} needed to retire in 2045.</h1>
        <h1>€#{at_65} needed to retire in 2050.</h1>
        <h1>€#{at_70} needed to retire in 2055.</h1>
      </body>
    </html>
    """

    html(conn, html)
  end

  defp format_number(number) do
    number
    |> to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.intersperse(",")
    |> Enum.reverse()
    |> Enum.join()
  end
end
