defmodule Microkernel.Telemetry do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  def record_telemetry(device_id, sensor_type, value, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:telemetry, device_id, sensor_type, value, metadata})
  end

  @impl true
  def handle_cast({:telemetry, device_id, sensor_type, value, metadata}, state) do
    timestamp = DateTime.utc_now()
    
    Phoenix.PubSub.broadcast(
      Microkernel.PubSub,
      "telemetry:#{device_id}",
      {:telemetry_update, %{
        device_id: device_id,
        sensor_type: sensor_type,
        value: value,
        metadata: metadata,
        timestamp: timestamp
      }}
    )
    
    Phoenix.PubSub.broadcast(
      Microkernel.PubSub,
      "telemetry:all",
      {:telemetry_update, %{
        device_id: device_id,
        sensor_type: sensor_type,
        value: value,
        metadata: metadata,
        timestamp: timestamp
      }}
    )

    {:noreply, state}
  end
end

