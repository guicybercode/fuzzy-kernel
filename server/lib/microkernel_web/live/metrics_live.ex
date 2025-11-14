defmodule MicrokernelWeb.MetricsLive do
  use MicrokernelWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5000, self(), :update_metrics)
    end
    {:ok, assign(socket, metrics: get_metrics())}
  end

  def handle_info(:update_metrics, socket) do
    {:noreply, assign(socket, metrics: get_metrics())}
  end

  defp get_metrics do
    try do
      metrics_text = Prometheus.Format.Text.format()
      parse_metrics(metrics_text)
    rescue
      _ -> %{}
    end
  end

  defp parse_metrics(text) do
    lines = String.split(text, "\n")
    Enum.reduce(lines, %{}, fn line, acc ->
      case String.split(line, " ") do
        [name, value] ->
          case Float.parse(value) do
            {float_value, _} -> Map.put(acc, name, float_value)
            :error -> acc
          end
        _ ->
          acc
      end
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6">System Metrics</h1>
      
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <%= for {name, value} <- @metrics do %>
          <div class="bg-white rounded-lg shadow p-4">
            <h3 class="text-sm font-medium text-gray-500"><%= name %></h3>
            <p class="text-2xl font-bold"><%= :erlang.float_to_binary(value, decimals: 2) %></p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end

