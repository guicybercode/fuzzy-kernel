defmodule Microkernel.Jobs.HealthCheckJob do
  use Oban.Worker, queue: :default, max_attempts: 1

  @impl Oban.Worker
  def perform(_job) do
    require Logger

    offline_devices =
      Microkernel.Devices.Registry.list_devices()
      |> Enum.filter(fn device ->
        if device.last_seen do
          DateTime.diff(DateTime.utc_now(), device.last_seen, :second) > 300
        else
          true
        end
      end)

    if length(offline_devices) > 0 do
      Logger.warning("Found #{length(offline_devices)} offline devices")
      Enum.each(offline_devices, fn device ->
        Microkernel.Devices.Registry.update_device_status(device.device_id, "offline")
      end)
    end

    :ok
  end
end

