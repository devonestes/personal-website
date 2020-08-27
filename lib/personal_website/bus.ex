defmodule PersonalWebsite.Bus do
  @moduledoc """
  Dealing with BVG data for our bus.
  """

  require Logger

  @url "http://fahrinfo.vbb.de/bin/mgate.exe?rnd=1597826703919"

  @payload """
  {
    "id":"7jim4r96kiwtgk4c",
    "ver":"1.33",
    "lang":"deu",
    "auth":{
      "type":"AID",
      "aid":"hafas-vbb-webapp"
    },
    "client":{
      "id":"VBB",
      "type":"WEB",
      "name":"VBB WebApp",
      "l":"vs_webapp_vbb"
    },
    "formatted":false,
    "svcReqL":[
      {
        "req":{
          "stbLoc":{
            "name":"Lückhoffstr. (Berlin)",
            "lid":"A=1@O=Lückhoffstr. (Berlin)@X=13206682@Y=52434016@U=86@L=900052253@B=1@V=3.9,@p=1597320470@"
          },
          "jnyFltrL":[
            {
              "type":"PROD",
              "mode":"INC",
              "value":127
            }
          ],
          "type":"DEP",
          "sort":"PT"
        },
        "meth":"StationBoard",
        "id":"1|1|"
      }
    ]
  }
  """

  def request_data() do
    {results, 0} = System.cmd("curl", [@url, "-s", "--data-binary", @payload, "--compressed"])
    parse_results(results)
  end

  def parse_results(results) do
    parsed =
      results
      |> Jason.decode!()
      |> Map.get("svcResL")
      |> hd()
      |> Map.get("res")

    bus_times(parsed["jnyL"])
  end

  defp bus_times(raw_times) do
    Logger.warn(inspect(raw_times))
    {alert, bus_times} = raw_times |> parse() |> Map.pop(:alert)

    bus_times =
      bus_times
      |> Enum.map(fn {k, v} -> {k, v |> Enum.reverse() |> Enum.take(2)} end)
      |> Enum.reverse()

    {alert, bus_times}
  end

  defp parse(raw_times) do
    Enum.reduce(raw_times, %{}, fn raw, acc ->
      case time_diff(raw["stbStop"]) do
        diff when diff > 0 ->
          direction = flag_to_human(raw["dirFlg"])
          {color, alert} = color_and_alert(diff, direction)

          duration =
            diff
            |> Timex.Duration.from_seconds()
            |> Timex.format_duration(:humanized)

          acc
          |> Map.update(direction, [{color, duration}], &[{color, duration} | &1])
          |> Map.update(:alert, alert, fn
            existing -> if is_nil(existing), do: alert, else: existing
          end)

        _ ->
          acc
      end
    end)
  end

  defp time_diff(stop_info) do
    stop_info
    |> Map.get("dTimeR", stop_info["dTimeS"])
    |> Timex.parse("{h24}{m}{s}")
    |> elem(1)
    |> Time.diff(Timex.now("Europe/Berlin"))
    |> Integer.floor_div(60)
    |> Kernel.*(60)
  end

  defp color_and_alert(seconds, _) when seconds <= 180, do: {:red, nil}

  defp color_and_alert(seconds, "← Zehlendorf") when seconds <= 300,
    do: {:orange, "/sounds/Zehlendorf5.wav"}

  defp color_and_alert(seconds, "S-Bahn →") when seconds <= 300,
    do: {:orange, "/sounds/S-Bahn5.wav"}

  defp color_and_alert(seconds, "← Zehlendorf") when seconds <= 600,
    do: {:green, "/sounds/Zehlendorf10.wav"}

  defp color_and_alert(seconds, "S-Bahn →") when seconds <= 600,
    do: {:green, "/sounds/S-Bahn10.wav"}

  defp color_and_alert(_, _), do: {:black, nil}

  defp flag_to_human("1"), do: "← Zehlendorf"
  defp flag_to_human(_), do: "S-Bahn →"
end
