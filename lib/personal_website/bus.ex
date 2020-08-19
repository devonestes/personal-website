defmodule PersonalWebsite.Bus do
  @moduledoc """
  Dealing with BVG data for our bus.
  """

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
    parsed = :maps.map(fn _, v -> v |> Enum.reverse() |> Enum.take(2) end, parse(raw_times))

    parsed
    |> Map.put("← Zehlendorf", parsed["1"])
    |> Map.put("S-Bahn →", parsed["2"])
    |> Map.drop(["1", "2"])
    |> Enum.to_list()
    |> Enum.reverse()
  end

  defp parse(raw_times) do
    Enum.reduce(raw_times, %{}, fn raw, acc ->
      stop_info = raw["stbStop"]
      time = Map.get(stop_info, "dTimeR", stop_info["dTimeS"])
      now = Timex.now("Europe/Berlin")
      {:ok, time} = Timex.parse(time, "{h24}{m}{s}")

      color =
        case now |> Time.diff(time) |> abs() do
          seconds when seconds < 180 -> :red
          seconds when seconds < 300 -> :orange
          _ -> :green
        end

      {:ok, formatted} = Timex.format(time, "{h24}:{m}")

      Map.update(acc, raw["dirFlg"], [{color, formatted}], &[{color, formatted} | &1])
    end)
  end
end
