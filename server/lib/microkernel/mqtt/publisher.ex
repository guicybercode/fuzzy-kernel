defmodule Microkernel.MQTT.Publisher do
  require Logger

  def publish_command(device_id, command, payload \\ %{}) do
    mqtt_config = Application.get_env(:microkernel, :mqtt)
    
    {:ok, pid} = :emqtt.start_link([
      host: to_charlist(mqtt_config[:host]),
      port: mqtt_config[:port],
      clientid: to_charlist("#{mqtt_config[:client_id]}_publisher_#{:rand.uniform(1000)}")
    ])

    case :emqtt.connect(pid) do
      {:ok, _props} ->
        topic = "devices/#{device_id}/commands"
        
        message = Jason.encode!(%{
          command: command,
          payload: payload,
          timestamp: DateTime.utc_now() |> DateTime.to_unix()
        })
        
        :emqtt.publish(pid, topic, message, qos: 1)
        Logger.info("Published command '#{command}' to #{device_id}")
        
        :emqtt.disconnect(pid)
        :ok

      {:error, reason} ->
        Logger.error("Failed to publish command: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def request_update(device_id, firmware_version) do
    publish_command(device_id, "update", %{version: firmware_version})
  end

  def restart_device(device_id) do
    publish_command(device_id, "restart")
  end

  def configure_device(device_id, config) do
    publish_command(device_id, "configure", config)
  end
end

