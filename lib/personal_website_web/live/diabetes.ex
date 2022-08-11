defmodule PersonalWebsiteWeb.Diabetes do
  use PersonalWebsiteWeb, :live_view

  alias PersonalWebsite.Diabetes

  def mount(_params, _session, socket) do
    Process.send_after(self(), :check_bg, 30_000)
    params = get_connect_params(socket)
    {_, bg} = Diabetes.update_data(params["timezone_offset"] || 1)

    {:ok,
     assign(socket,
       timezone_offset: params["timezone_offset"],
       sound: "Enable sound",
       alert: nil,
       bg: bg
     )}
  end

  def handle_info(:check_bg, socket) do
    Process.send_after(self(), :check_bg, 30_000)
    {alert, bg} = Diabetes.update_data(socket.assigns.timezone_offset)
    {:noreply, assign(socket, alert: alert, bg: bg)}
  end

  def handle_event("toggle-sound", _, socket) do
    sound = if socket.assigns.sound == "Enable sound", do: "Disable sound", else: "Enable sound"
    {:noreply, assign(socket, sound: sound)}
  end

  def render(assigns) do
    ~L"""
    <div style="text-align:center;margin-bottom:50px">
      <div style="display:none">
        <audio id="audio-alert" src="<%= unless is_nil(assigns.alert), do: Routes.static_path(assigns.socket, assigns.alert) %>"/>
      </div>
      <h1>Nightscout</h1>
      <h2><%= assigns.bg %></h2>
      <button style="margin:0 auto" phx-click="toggle-sound"><%= assigns.sound %></button>
    </div>
    """
  end
end
