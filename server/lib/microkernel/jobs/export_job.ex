defmodule Microkernel.Jobs.ExportJob do
  use Oban.Worker
  alias Microkernel.Telemetry
  alias Microkernel.Devices.Registry

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"schedule_id" => schedule_id}}) do
    schedule = Microkernel.Repo.get(Microkernel.Exports.ExportSchedule, schedule_id)
    
    if schedule && schedule.active do
      case schedule.format do
        "csv" -> export_csv(schedule)
        "json" -> export_json(schedule)
        _ -> {:error, "Unsupported format"}
      end
    else
      :ok
    end
  end

  defp export_csv(schedule) do
    readings = if schedule.device_id do
      Telemetry.get_readings(schedule.device_id, limit: 10000)
    else
      []
    end

    csv_data = generate_csv(readings)
    send_export(schedule, csv_data, "text/csv")
  end

  defp export_json(schedule) do
    data = if schedule.device_id do
      device = Registry.get_device(schedule.device_id)
      readings = Telemetry.get_readings(schedule.device_id, limit: 10000)
      %{device: device, readings: readings}
    else
      devices = Registry.list_devices()
      %{devices: devices}
    end

    json_data = Jason.encode!(data)
    send_export(schedule, json_data, "application/json")
  end

  defp generate_csv(readings) do
    header = "timestamp,device_id,sensor_type,value,unit\n"
    rows = Enum.map(readings, fn r ->
      "#{r.timestamp},#{r.device_id},#{r.sensor_type},#{r.value},#{r.unit || ""}\n"
    end)
    header <> Enum.join(rows)
  end

  defp send_export(schedule, data, content_type) do
    if schedule.destination do
      Task.start(fn ->
        request = Finch.build(:post, schedule.destination, [{"Content-Type", content_type}], data)
        _ = Finch.request(request, Microkernel.Finch)
      end)
    end
    :ok
  end
end

