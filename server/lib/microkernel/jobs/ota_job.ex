defmodule Microkernel.Jobs.OTAJob do
  use Oban.Worker, queue: :ota, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"device_id" => device_id, "version" => version}}) do
    require Logger
    Logger.info("Processing OTA update for device #{device_id} to version #{version}")

    case Microkernel.MQTT.Publisher.request_update(device_id, version) do
      :ok ->
        Microkernel.OTA.Updater.update_deployment_status(device_id, :in_progress)
        :ok

      error ->
        Microkernel.OTA.Updater.update_deployment_status(device_id, :failed)
        {:error, error}
    end
  end
end

