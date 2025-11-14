defmodule MicrokernelWeb.DeviceLive.Charts do
  use MicrokernelWeb, :live_view
  alias Microkernel.Devices.Registry
  alias Microkernel.Telemetry

  @impl true
  def mount(%{"id" => device_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Microkernel.PubSub, "telemetry:#{device_id}")
    end

    case Registry.get_device(device_id) do
      nil ->
        {:ok, socket |> put_flash(:error, "Device not found") |> redirect(to: ~p"/")}

      device ->
        readings = Telemetry.get_readings(device_id, limit: 1000, since: time_range_to_datetime("1h"))
        chart_data = prepare_chart_data(readings)
        
        {:ok, assign(socket, 
          device: device, 
          device_id: device_id,
          chart_data: chart_data,
          time_range: "1h",
          sensor_types: get_sensor_types(readings)
        )}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    time_range = Map.get(params, "range", socket.assigns[:time_range] || "1h")
    sensor_filter = Map.get(params, "sensor", socket.assigns[:sensor_filter])
    
    since = time_range_to_datetime(time_range)
    readings = Telemetry.get_readings(socket.assigns.device_id, 
      limit: 1000, 
      since: since,
      sensor_type: sensor_filter
    )
    
    chart_data = prepare_chart_data(readings)
    
    {:noreply, assign(socket, 
      chart_data: chart_data,
      time_range: time_range,
      sensor_filter: sensor_filter
    )}
  end

  @impl true
  def handle_info({:telemetry_update, data}, socket) do
    if data.device_id == socket.assigns.device_id do
      since = time_range_to_datetime(socket.assigns.time_range)
      readings = Telemetry.get_readings(socket.assigns.device_id, 
        limit: 1000, 
        since: since,
        sensor_type: socket.assigns[:sensor_filter]
      )
      chart_data = prepare_chart_data(readings)
      {:noreply, assign(socket, chart_data: chart_data)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("change_range", %{"range" => range}, socket) do
    {:noreply, push_patch(socket, to: ~p"/devices/#{socket.assigns.device_id}/charts?range=#{range}")}
  end

  @impl true
  def handle_event("filter_sensor", %{"sensor" => sensor}, socket) do
    filter = if sensor == "all", do: nil, else: sensor
    {:noreply, push_patch(socket, to: ~p"/devices/#{socket.assigns.device_id}/charts?range=#{socket.assigns.time_range}&sensor=#{filter || "all"}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-4">
        <.link navigate={~p"/devices/#{@device.device_id}"} class="text-blue-600 hover:text-blue-800">
          ← Back to device
        </.link>
      </div>

      <div class="bg-white shadow rounded-lg p-6 mb-4">
        <h2 class="text-2xl font-semibold text-gray-900 mb-4">
          Historical Charts - <%= @device.name || @device.device_id %>
        </h2>

        <div class="flex flex-wrap gap-4 mb-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Time Range</label>
            <select 
              phx-change="change_range" 
              name="range" 
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            >
              <option value="1h" selected={@time_range == "1h"}>Last Hour</option>
              <option value="6h" selected={@time_range == "6h"}>Last 6 Hours</option>
              <option value="24h" selected={@time_range == "24h"}>Last 24 Hours</option>
              <option value="7d" selected={@time_range == "7d"}>Last 7 Days</option>
              <option value="30d" selected={@time_range == "30d"}>Last 30 Days</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Sensor Filter</label>
            <select 
              phx-change="filter_sensor" 
              name="sensor" 
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            >
              <option value="all" selected={@sensor_filter == nil}>All Sensors</option>
              <%= for sensor_type <- @sensor_types do %>
                <option value={sensor_type} selected={@sensor_filter == sensor_type}><%= sensor_type %></option>
              <% end %>
            </select>
          </div>
        </div>
      </div>

      <div class="bg-white shadow rounded-lg p-6">
        <div class="h-96">
          <canvas 
            id="telemetry-chart" 
            phx-hook="Chart"
            data-chart-data={Jason.encode!(@chart_data)}
            data-chart-options={Jason.encode!(%{responsive: true, maintainAspectRatio: false})}
          >
          </canvas>
        </div>
      </div>
    </div>
    """
  end

  defp prepare_chart_data(readings) do
    readings = Enum.reverse(readings)
    
    sensor_groups = Enum.group_by(readings, & &1.sensor_type)
    
    datasets = Enum.map(sensor_groups, fn {sensor_type, sensor_readings} ->
      %{
        label: sensor_type,
        data: Enum.map(sensor_readings, fn r ->
          %{
            x: DateTime.to_iso8601(r.timestamp),
            y: r.value
          }
        end),
        borderColor: color_for_sensor(sensor_type),
        backgroundColor: color_for_sensor(sensor_type) |> String.replace("rgb", "rgba") |> String.replace(")", ", 0.1)"),
        tension: 0.4,
        fill: false
      }
    end)

    %{
      datasets: datasets
    }
  end

  defp color_for_sensor("temperature"), do: "rgb(239, 68, 68)"
  defp color_for_sensor("humidity"), do: "rgb(59, 130, 246)"
  defp color_for_sensor("pressure"), do: "rgb(34, 197, 94)"
  defp color_for_sensor("light"), do: "rgb(234, 179, 8)"
  defp color_for_sensor(_), do: "rgb(156, 163, 175)"

  defp get_sensor_types(readings) do
    readings
    |> Enum.map(& &1.sensor_type)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp time_range_to_datetime("1h"), do: DateTime.add(DateTime.utc_now(), -3600, :second)
  defp time_range_to_datetime("6h"), do: DateTime.add(DateTime.utc_now(), -21600, :second)
  defp time_range_to_datetime("24h"), do: DateTime.add(DateTime.utc_now(), -86400, :second)
  defp time_range_to_datetime("7d"), do: DateTime.add(DateTime.utc_now(), -604800, :second)
  defp time_range_to_datetime("30d"), do: DateTime.add(DateTime.utc_now(), -2592000, :second)
  defp time_range_to_datetime(_), do: DateTime.add(DateTime.utc_now(), -3600, :second)
end

