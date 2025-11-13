defmodule Microkernel.MQTT.Subscriber do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    mqtt_config = Application.get_env(:microkernel, :mqtt)
    
    {:ok, pid} = :emqtt.start_link([
      host: to_charlist(mqtt_config[:host]),
      port: mqtt_config[:port],
      clientid: to_charlist(mqtt_config[:client_id])
    ])

    case :emqtt.connect(pid) do
      {:ok, _props} ->
        Logger.info("Connected to MQTT broker at #{mqtt_config[:host]}:#{mqtt_config[:port]}")
        
        :emqtt.subscribe(pid, {"devices/+/telemetry", 1})
        Logger.info("Subscribed to devices/+/telemetry")
        
        {:ok, %{client: pid}}

      {:error, reason} ->
        Logger.error("Failed to connect to MQTT broker: #{inspect(reason)}")
        {:ok, %{client: nil}}
    end
  end

  @impl true
  def handle_info({:publish, packet}, state) do
    topic = Map.get(packet, :topic)
    payload = Map.get(packet, :payload)
    
    Logger.debug("Received MQTT message on topic: #{topic}")
    
    case parse_topic(topic) do
      {:ok, device_id} ->
        handle_telemetry(device_id, payload)
      
      :error ->
        Logger.warning("Unable to parse topic: #{topic}")
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("Unhandled MQTT message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp parse_topic(topic) when is_binary(topic) do
    case String.split(topic, "/") do
      ["devices", device_id, "telemetry"] -> {:ok, device_id}
      _ -> :error
    end
  end

  defp parse_topic(_), do: :error

  defp handle_telemetry(device_id, payload) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, data} ->
        Microkernel.Devices.Registry.heartbeat(device_id)
        
        Microkernel.Telemetry.record_telemetry(
          device_id,
          data["sensor"],
          data["value"],
          %{
            unit: data["unit"],
            timestamp: data["timestamp"],
            anomaly: data["anomaly"],
            confidence: data["confidence"]
          }
        )
        
        Logger.info("Telemetry from #{device_id}: #{data["sensor"]} = #{data["value"]} #{data["unit"]}")

      {:error, reason} ->
        Logger.error("Failed to parse telemetry payload: #{inspect(reason)}")
    end
  end

  defp handle_telemetry(_device_id, _payload), do: :ok
end

