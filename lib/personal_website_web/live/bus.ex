defmodule PersonalWebsiteWeb.Bus do
  use PersonalWebsiteWeb, :live_view

  alias PersonalWebsite.Bus

  def mount(_params, _session, socket) do
    get_data(:ok, socket)
  end

  def handle_info(:update_time, socket) do
    get_data(:noreply, socket)
  end

  def handle_info(:update_bus_data, socket) do
    get_data(:noreply, socket)
  end

  def render(assigns) do
    alert = unless is_nil(assigns.alert), do: Routes.static_path(assigns.socket, assigns.alert)

    ~L"""
    <div>
      <div style="display:none">
        <audio id="audio-alert" src="<%= alert %>"/>
      </div>
      <h1 style="text-align:center;font-size:30px"><%= assigns.date %></h1>
      <h1 id="time" style="text-align:center;font-size:30px"><%= assigns.time %></h1>
      <table style="width:fit-content;margin:0 auto">
        <tr>
          <%= for {destination, _} <- assigns.bus_data do %>
            <th style="font-size:30px;padding:10px 50px;background:white;border:none;text-align:center"><%= destination %></th>
          <% end %>
        </tr>
        <tr>
          <%= for {_, times} <- assigns.bus_data do %>
            <td style="border:none">
              <%= for {color, time} <- times do %>
                <p style="font-size:50px;text-align:center;font-weight:900;color:<%= color %>"><%= time %></p>
              <% end %>
            </td>
          <% end %>
        </tr>
      </table>
      <button>Enable sound</button>
    </div>
    """
  end

  defp get_data(atom, socket) do
    now = Timex.now("Europe/Berlin")
    {:ok, date} = Timex.format(now, "{WDfull} {Mfull} {D}")
    {:ok, time} = Timex.format(now, "{h24}:{m}:{s}")
    if String.ends_with?(time, "0") or atom == :ok do
      Process.send_after(self(), :update_bus_data, 10_000)
      Process.send_after(self(), :update_time, 1000)
      {alert, bus_data} = Bus.request_data()
      {atom, assign(socket, date: date, time: time, bus_data: bus_data, alert: alert)}
    else
      Process.send_after(self(), :update_time, 1000)
      {atom, assign(socket, date: date, time: time)}
    end
  end
end
