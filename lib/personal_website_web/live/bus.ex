defmodule PersonalWebsiteWeb.Bus do
  use PersonalWebsiteWeb, :live_view

  alias PersonalWebsite.Bus

  def mount(_params, _session, socket) do
    {_, socket} = handle_info(:update_bus_data, socket)
    {_, socket} = handle_info(:update_time, socket)
    {:ok, assign(socket, sound: "Enable sound", alert: nil, bus_data: [])}
  end

  def handle_info(:update_bus_data, socket) do
    me = self()
    spawn(fn ->
      send(me, Bus.request_data())
      Process.send_after(me, :update_bus_data, 10_000)
    end)
    {:noreply, socket}
  end

  def handle_info(:update_time, socket) do
    Process.send_after(self(), :update_time, 1000)
    now = Timex.now("Europe/Berlin")
    {:ok, date} = Timex.format(now, "{WDfull} {Mfull} {D}")
    {:ok, time} = Timex.format(now, "{h24}:{m}:{s}")
    {:noreply, assign(socket, date: date, time: time)}
  end

  def handle_info({alert, bus_data}, socket) do
    {:noreply, assign(socket, bus_data: bus_data, alert: alert)}
  end

  def handle_event("toggle-sound", _, socket) do
    value =
      case socket.assigns.sound do
        "Enable sound" -> "Disable sound"
        _ -> "Enable sound"
      end

    {:noreply, assign(socket, :sound, value)}
  end

  def render(assigns) do
    ~L"""
    <div style="text-align:center;margin-bottom:50px">
      <div style="display:none">
        <audio id="audio-alert" src="<%= unless is_nil(assigns.alert), do: Routes.static_path(assigns.socket, assigns.alert) %>"/>
      </div>
      <h1 style="text-align:center;font-size:30px"><%= assigns.date %></h1>
      <h1 id="time" style="text-align:center;font-size:30px"><%= assigns.time %></h1>
      <div style="display:flex;flex-wrap:wrap;justify-content:center">
        <%= for {destination, times} <- assigns.bus_data do %>
          <div>
            <h2 style="font-size:30px;padding:10px 50px;background:white;border:none;text-align:center"><%= destination %></h2>
            <%= for {color, time} <- times do %>
              <p style="font-size:50px;text-align:center;font-weight:900;color:<%= color %>"><%= time %></p>
            <% end %>
          </div>
        <% end %>
      </div>
      <button style="margin:0 auto" phx-click="toggle-sound"><%= assigns.sound %></button>
    </div>
    """
  end
end
