defmodule Microkernel.Telemetry do
  use GenServer
  require Logger
  import Ecto.Query
  alias Microkernel.Repo
  alias Microkernel.Telemetry.Reading

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
    
    attrs = %{
      device_id: device_id,
      sensor_type: sensor_type,
      value: value,
      unit: metadata[:unit],
      anomaly: metadata[:anomaly] || false,
      confidence: metadata[:confidence],
      metadata: metadata,
      timestamp: metadata[:timestamp] || timestamp
    }

    case Repo.insert(Reading.changeset(%Reading{}, attrs)) do
      {:ok, _reading} ->
        Microkernel.Alerts.check_telemetry(device_id, sensor_type, value)
        :ok
      {:error, changeset} ->
        Logger.error("Failed to save telemetry: #{inspect(changeset.errors)}")
    end
    
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

  def get_readings(device_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    since = Keyword.get(opts, :since)
    sensor_type = Keyword.get(opts, :sensor_type)
    
    query = 
      from r in Reading,
      where: r.device_id == ^device_id,
      order_by: [desc: r.timestamp],
      limit: ^limit

    query = if since, do: from(r in query, where: r.timestamp >= ^since), else: query
    query = if sensor_type, do: from(r in query, where: r.sensor_type == ^sensor_type), else: query
    
    Repo.all(query)
  end

  def get_latest_reading(device_id, sensor_type \\ nil) do
    query = 
      from r in Reading,
      where: r.device_id == ^device_id,
      order_by: [desc: r.timestamp],
      limit: 1

    query = if sensor_type, do: from(r in query, where: r.sensor_type == ^sensor_type), else: query
    
    Repo.one(query)
  end
end

