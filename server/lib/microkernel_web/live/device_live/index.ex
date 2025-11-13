defmodule MicrokernelWeb.DeviceLive.Index do
  use MicrokernelWeb, :live_view
  alias Microkernel.Devices.Registry

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Microkernel.PubSub, "devices")
      Phoenix.PubSub.subscribe(Microkernel.PubSub, "telemetry:all")
    end

    devices = Registry.list_devices()
    {:ok, assign(socket, devices: devices, telemetry: %{})}
  end

  @impl true
  def handle_info({:device_registered, _device}, socket) do
    devices = Registry.list_devices()
    {:noreply, assign(socket, devices: devices)}
  end

  @impl true
  def handle_info({:device_updated, _device}, socket) do
    devices = Registry.list_devices()
    {:noreply, assign(socket, devices: devices)}
  end

  @impl true
  def handle_info({:device_status_changed, _device_id, _status}, socket) do
    devices = Registry.list_devices()
    {:noreply, assign(socket, devices: devices)}
  end

  @impl true
  def handle_info({:telemetry_update, data}, socket) do
    telemetry = Map.put(socket.assigns.telemetry, data.device_id, data)
    {:noreply, assign(socket, telemetry: telemetry)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-2xl font-semibold text-gray-900">IoT Devices</h1>
          <p class="mt-2 text-sm text-gray-700">A list of all connected IoT devices and their status.</p>
        </div>
      </div>
      
      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <%= for device <- @devices do %>
          <.link navigate={~p"/devices/#{device.device_id}"} class="block">
            <div class="bg-white overflow-hidden shadow rounded-lg hover:shadow-lg transition-shadow">
              <div class="px-4 py-5 sm:p-6">
                <div class="flex items-center justify-between">
                  <h3 class="text-lg font-medium text-gray-900"><%= device.name || device.device_id %></h3>
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{status_color(device.status)}"}>
                    <%= device.status %>
                  </span>
                </div>
                
                <dl class="mt-4 space-y-2">
                  <div>
                    <dt class="text-sm font-medium text-gray-500">Device ID</dt>
                    <dd class="text-sm text-gray-900"><%= device.device_id %></dd>
                  </div>
                  
                  <div>
                    <dt class="text-sm font-medium text-gray-500">Firmware</dt>
                    <dd class="text-sm text-gray-900"><%= device.firmware_version || "Unknown" %></dd>
                  </div>
                  
                  <div>
                    <dt class="text-sm font-medium text-gray-500">Last Seen</dt>
                    <dd class="text-sm text-gray-900">
                      <%= if device.last_seen do %>
                        <%= format_datetime(device.last_seen) %>
                      <% else %>
                        Never
                      <% end %>
                    </dd>
                  </div>
                  
                  <%= if Map.has_key?(@telemetry, device.device_id) do %>
                    <% data = @telemetry[device.device_id] %>
                    <div class="pt-2 border-t border-gray-200">
                      <dt class="text-sm font-medium text-gray-500">Latest Reading</dt>
                      <dd class="text-sm text-gray-900">
                        <%= data.sensor_type %>: <%= Float.round(data.value, 2) %> <%= data.metadata.unit %>
                        <%= if data.metadata.anomaly do %>
                          <span class="ml-2 text-red-600 font-semibold">⚠️ Anomaly</span>
                        <% end %>
                      </dd>
                    </div>
                  <% end %>
                </dl>
              </div>
            </div>
          </.link>
        <% end %>
      </div>
      
      <%= if Enum.empty?(@devices) do %>
        <div class="mt-8 text-center">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No devices</h3>
          <p class="mt-1 text-sm text-gray-500">No IoT devices are currently connected to the platform.</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp status_color("online"), do: "bg-green-100 text-green-800"
  defp status_color("offline"), do: "bg-gray-100 text-gray-800"
  defp status_color(_), do: "bg-yellow-100 text-yellow-800"

  defp format_datetime(nil), do: "Never"
  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end
end

