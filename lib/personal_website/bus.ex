defmodule PersonalWebsite.Bus do
  @moduledoc """
  Dealing with BVG data for our bus.
  """

  @url "http://fahrinfo.vbb.de/bin/mgate.exe"

  @home_payload """
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

  @am_volkspark_payload """
  {
    "id":"77mmerzi4gkxg644",
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
            "lid":"A=1@O=Am Volkspark (Berlin)@X=13320360@Y=52483664@U=86@L=900044102@B=1@V=3.9,@p=1598522826@",
            "type":"S",
            "name":"Am Volkspark (Berlin)",
            "icoX":1,
            "extId":"900044102",
            "state":"F",
            "crd":{
              "x":13320360,
              "y":52483664,
              "floor":0
            },
            "pCls":8,
            "pRefL":[
              0,
              1,
              2
            ],
            "wt":847,
            "gidL":[
              "A×de:11000:900044102"
            ]
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
        "id":"1|6|"
      }
    ]
  }
  """

  @zehlendorf_payload """
  {
    "id":"77mmerzi4gkxg644",
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
            "lid":"A=1@O=S Zehlendorf (Berlin)@X=13259224@Y=52431212@U=86@L=900049201@B=1@V=3.9,@p=1598522826@",
            "type":"S",
            "name":"S Zehlendorf (Berlin)",
            "icoX":2,
            "extId":"900049201",
            "state":"F",
            "crd":{
              "x":13259224,
              "y":52431212,
              "floor":0
            },
            "pCls":9,
            "pRefL":[
              0,
              1,
              2,
              3,
              4,
              5,
              6,
              7,
              8,
              9,
              10,
              11
            ],
            "wt":13798,
            "gidL":[
              "A×de:11000:900049201"
            ]
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
        "id":"1|18|"
      }
    ]
  }
  """

  def request_data() do
    {home_results, 0} =
      System.cmd("curl", [@url, "-s", "--data-binary", @home_payload, "--compressed"])

    {volkspark_results, 0} =
      System.cmd("curl", [@url, "-s", "--data-binary", @am_volkspark_payload, "--compressed"])

    {zehlendorf_results, 0} =
      System.cmd("curl", [@url, "-s", "--data-binary", @zehlendorf_payload, "--compressed"])

    volkspark_results =
      volkspark_results
      |> Jason.decode!()
      |> Map.get("svcResL")
      |> hd()
      |> Map.get("res")
      |> Map.get("jnyL")
      |> Enum.filter(fn raw ->
        raw["dirTxt"] in ["Grunewald, Roseneck", "U Wilmersdorfer Str./S Charlottenburg"]
      end)
      |> Enum.reduce(%{}, fn raw, acc ->
        case time_diff(raw["stbStop"]) do
          diff when diff > 0 ->
            duration =
              diff
              |> Timex.Duration.from_seconds()
              |> Timex.format_duration(:humanized)

            {color, _} = color_and_alert(diff, nil)

            Map.update(
              acc,
              "Heidelberger Platz →",
              [{color, duration}],
              &[{color, duration} | &1]
            )

          _ ->
            acc
        end
      end)
      |> Enum.map(fn {k, v} -> {k, v |> Enum.reverse() |> Enum.take(2)} end)

     zehlendorf_results =
      zehlendorf_results
      |> Jason.decode!()
      |> Map.get("svcResL")
      |> hd()
      |> Map.get("res")
      |> Map.get("jnyL")
      |> Enum.filter(fn raw ->
        raw["dirTxt"] in ["U Turmstr.", "S Nikolassee"]
      end)
      |> Enum.reduce(%{}, fn raw, acc ->
        case time_diff(raw["stbStop"]) do
          diff when diff > 0 ->
            direction =
              case raw["dirTxt"] do
                "U Turmstr." -> "101 Chiquitita →"
                _ ->  "112 Home →"
              end

            {color, _} = color_and_alert(diff, direction)

            duration =
              diff
              |> Timex.Duration.from_seconds()
              |> Timex.format_duration(:humanized)

            Map.update(
              acc,
              direction,
              [{color, duration}],
              &[{color, duration} | &1]
            )

          _ ->
            acc
        end
      end)
      |> Enum.map(fn {k, v} -> {k, v |> Enum.reverse() |> Enum.take(2)} end)

    {alert, bus_times} = parse_results(home_results)
    {alert, bus_times ++ volkspark_results ++ zehlendorf_results}
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
