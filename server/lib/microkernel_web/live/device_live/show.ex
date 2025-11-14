defmodule MicrokernelWeb.DeviceLive.Show do
  use MicrokernelWeb, :live_view
  alias Microkernel.Devices.Registry
  alias Microkernel.MQTT.Publisher

  @impl true
  def mount(%{"id" => device_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Microkernel.PubSub, "telemetry:#{device_id}")
      Phoenix.PubSub.subscribe(Microkernel.PubSub, "devices")
    end

    case Registry.get_device(device_id) do
      nil ->
        {:ok, socket |> put_flash(:error, "Device not found") |> redirect(to: ~p"/")}

      device ->
        {:ok, assign(socket, device: device, telemetry_history: [], device_id: device_id)}
    end
  end

  @impl true
  def handle_info({:telemetry_update, data}, socket) do
    if data.device_id == socket.assigns.device_id do
      history = [data | Enum.take(socket.assigns.telemetry_history, 49)]
      {:noreply, assign(socket, telemetry_history: history)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:device_updated, device}, socket) do
    if device.device_id == socket.assigns.device_id do
      {:noreply, assign(socket, device: device)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:device_status_changed, device_id, _status}, socket) do
    if device_id == socket.assigns.device_id do
      device = Registry.get_device(device_id)
      {:noreply, assign(socket, device: device)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def handle_event("restart_device", _params, socket) do
    Publisher.restart_device(socket.assigns.device_id)
    {:noreply, put_flash(socket, :info, "Restart command sent to device")}
  end

  @impl true
  def handle_event("update_firmware", _params, socket) do
    Publisher.request_update(socket.assigns.device_id, "1.0.0")
    {:noreply, put_flash(socket, :info, "Firmware update initiated")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-4">
        <.link navigate={~p"/"} class="text-blue-600 hover:text-blue-800">
          ← Back to devices
        </.link>
      </div>
      
      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
          <div>
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              <%= @device.name || @device.device_id %>
            </h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">Device details and telemetry</p>
          </div>
          <span class={"px-3 py-1 inline-flex text-sm leading-5 font-semibold rounded-full #{status_color(@device.status)}"}>
            <%= @device.status %>
          </span>
        </div>
        
        <div class="border-t border-gray-200 px-4 py-5 sm:p-0">
          <dl class="sm:divide-y sm:divide-gray-200">
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Device ID</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @device.device_id %></dd>
            </div>
            
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Firmware Version</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @device.firmware_version || "Unknown" %></dd>
            </div>
            
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Last Seen</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <%= if @device.last_seen do %>
                  <%= format_datetime(@device.last_seen) %>
                <% else %>
                  Never
                <% end %>
              </dd>
            </div>
            
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Actions</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2 space-x-2">
                <button phx-click="restart_device" class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none">
                  Restart Device
                </button>
                <button phx-click="update_firmware" class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none">
                  Update Firmware
                </button>
              </dd>
            </div>
          </dl>
        </div>
      </div>
      
      <div class="mt-8">
        <h3 class="text-lg font-medium text-gray-900 mb-4">Real-time Telemetry</h3>
        
        <%= if Enum.empty?(@telemetry_history) do %>
          <div class="bg-white shadow rounded-lg p-6 text-center">
            <p class="text-gray-500">Waiting for telemetry data...</p>
          </div>
        <% else %>
          <div class="bg-white shadow rounded-lg overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Timestamp</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sensor</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Value</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for reading <- @telemetry_history do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <%= format_datetime(reading.timestamp) %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      <%= reading.sensor_type %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <%= Float.round(reading.value, 2) %> <%= reading.metadata.unit %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm">
                      <%= if reading.metadata.anomaly do %>
                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">
                          ⚠️ Anomaly (<%= Float.round(reading.metadata.confidence * 100, 1) %>%)
                        </span>
                      <% else %>
                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                          Normal
                        </span>
                      <% end %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_color("online"), do: "bg-green-100 text-green-800"
  defp status_color("offline"), do: "bg-gray-100 text-gray-800"
  defp status_color(_), do: "bg-yellow-100 text-yellow-800"

  defp format_datetime(nil), do: "Never"
  defp format_datetime(datetime) when is_struct(datetime, DateTime) do
    datetime
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
  end
  defp format_datetime(_), do: "Invalid"
end

