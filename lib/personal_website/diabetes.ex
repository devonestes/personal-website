defmodule PersonalWebsite.Diabetes do
  @moduledoc """
  Handling logic for setting alarms
  """

  @route "https://felix-nightscout.herokuapp.com/api/v1/entries.json"

  @low_alarm "/sounds/Zehlendorf10.wav"
  @high_alarm "/sounds/Zehlendorf5.wav"

  def update_data(timezone_offset) do
    now = DateTime.add(DateTime.utc_now(), timezone_offset * 3600, :second)
    get_data() |> get_alarm_data(now)
  end

  def get_data() do
    {:ok, %{body: body}} = Tesla.get(@route)

    Jason.decode!(body)
    |> Enum.map(&parse_data(&1))
    |> Enum.sort_by(& &1.time, {:desc, DateTime})
    |> Enum.take(3)
  end

  defp parse_data(raw) do
    {:ok, time, _} = DateTime.from_iso8601(raw["dateString"])
    %{bg: raw["sgv"], time: time}
  end

  defp get_alarm_data([%{bg: bg} | tail] = raw_data, now) do
    fall_rate = (Enum.reduce(tail, {bg, 0}, &calculate_fall_rate/2) |> elem(1)) / length(raw_data)
    calcuate_alarm(bg, fall_rate, now.hour, now.minute)
  end

  defp calculate_fall_rate(%{bg: bg}, {previous, total}), do: {bg, total + bg - previous}

  defp calcuate_alarm(bg, _, _, _) when bg <= 55 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, _, _, _) when bg >= 250 do
    {@high_alarm, bg}
  end

  defp calcuate_alarm(bg, fall_rate, _, _) when fall_rate >= 30 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, fall_rate, _, _) when fall_rate <= -30 do
    {@high_alarm, bg}
  end

  defp calcuate_alarm(bg, fall_rate, _, _) when bg <= 85 and fall_rate >= 10 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, fall_rate, _, _) when bg >= 200 and fall_rate < -10 do
    {@high_alarm, bg}
  end

  defp calcuate_alarm(bg, _, hour, _) when hour < 2 and bg <= 100 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, fall_rate, hour, _) when hour < 2 and bg <= 120 and fall_rate > 10 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, _, hour, _) when hour < 4 and bg <= 85 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, fall_rate, hour, _) when hour < 4 and bg <= 100 and fall_rate >= 4 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, fall_rate, hour, _) when hour < 7 and bg <= 80 and fall_rate >= 4 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, _, hour, _) when hour < 7 and bg <= 60 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, _, hour, _) when hour < 19 and bg <= 70 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, fall_rate, hour, _) when hour < 22 and hour >= 19 and bg <= 140 and fall_rate > 10 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, _, hour, _) when hour < 22 and hour >= 19 and bg <= 120 do
    {@low_alarm, bg}
  end

  defp calcuate_alarm(bg, _, _, _), do: {nil, bg}
end
