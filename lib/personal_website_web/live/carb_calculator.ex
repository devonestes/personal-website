defmodule PersonalWebsiteWeb.CarbCalculator do
  use PersonalWebsiteWeb, :live_view

  def mount(_params, _session, socket) do
    %{hour: hour} = Timex.now("Europe/Berlin")

    sensitivity_factor =
      cond do
        hour >= 0 and hour <= 8 -> 1.0
        hour >= 9 and hour <= 16 -> 0.3
        hour >= 17 and hour <= 19 -> 1.5
        hour >= 20 and hour <= 23 -> 0.5
      end

    {:ok,
     assign(socket, carb_units: 0.0, sensitivity_factor: sensitivity_factor, insulin_units: 0.0)}
  end

  def handle_event("update", %{"calculator" => %{"carb_units" => units}}, socket) do
    units =
      case Float.parse(units) do
        {units, ""} -> units
        _ -> 0.0
      end

    insulin_units = Float.floor(units * socket.assigns.sensitivity_factor, 1)
    {:noreply, assign(socket, carb_units: units, insulin_units: insulin_units)}
  end

  def render(assigns) do
    ~H"""
    <div style="text-align:center;margin-bottom:50px">
      <form id="calculator" phx-change="update">
        <div>
          <label for="calculator_carb_units">Carb units (KE)</label>
          <input
            type="text"
            id="calculator_carb_units"
            name="calculator[carb_units]"
            inputmode="decimal"
            pattern="[0-9\.]*"
            phx-debounce="100"
            value={@carb_units}
          />
        </div>

        <div>
          <label for="calculator_sensitivity_factor">Sensitivity factor</label>
          <input
            type="text"
            id="calculator_sensitivity_factor"
            name="calculator[sensitivity_factor]"
            inputmode="decimal"
            pattern="[0-9\.]*"
            phx-debounce="100"
            value={@sensitivity_factor}
          />
        </div>
      </form>

      <h1>Give <b>{@insulin_units}</b> units of insulin</h1>
    </div>
    """
  end
end
