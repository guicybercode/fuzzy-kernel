defmodule MicrokernelWeb.Api.ExportController do
  use MicrokernelWeb, :controller
  alias Microkernel.Telemetry
  alias Microkernel.Devices.Registry

  def export_telemetry(conn, %{"device_id" => device_id} = params) do
    format = params["format"] || "csv"
    since = params["since"] |> parse_since()
    sensor_type = params["sensor_type"]

    readings = Telemetry.get_readings(device_id, limit: 10000, since: since, sensor_type: sensor_type)

    case format do
      "csv" ->
        csv_data = generate_csv(readings)
        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header("content-disposition", "attachment; filename=\"telemetry_#{device_id}_#{timestamp()}.csv\"")
        |> send_resp(200, csv_data)

      "json" ->
        json_data = Jason.encode!(readings, pretty: true)
        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header("content-disposition", "attachment; filename=\"telemetry_#{device_id}_#{timestamp()}.json\"")
        |> send_resp(200, json_data)

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid format. Use 'csv' or 'json'"})
    end
  end

  def export_devices(conn, _params) do
    devices = Registry.list_devices()

    json_data = Jason.encode!(devices, pretty: true)

    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("content-disposition", "attachment; filename=\"devices_#{timestamp()}.json\"")
    |> send_resp(200, json_data)
  end

  defp generate_csv(readings) do
    headers = "timestamp,device_id,sensor_type,value,unit,anomaly,confidence\n"

    rows =
      Enum.map(readings, fn reading ->
        timestamp = reading.timestamp |> DateTime.to_iso8601()
        device_id = escape_csv(reading.device_id)
        sensor_type = escape_csv(reading.sensor_type)
        value = Float.to_string(reading.value)
        unit = escape_csv(reading.unit || "")
        anomaly = if reading.anomaly, do: "true", else: "false"
        confidence = if reading.confidence, do: Float.to_string(reading.confidence), else: ""

        "#{timestamp},#{device_id},#{sensor_type},#{value},#{unit},#{anomaly},#{confidence}\n"
      end)

    headers <> Enum.join(rows, "")
  end

  defp escape_csv(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end

  defp escape_csv(value), do: to_string(value)

  defp parse_since(nil), do: nil
  defp parse_since(since) when is_binary(since) do
    case DateTime.from_iso8601(since) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_since(since), do: since

  defp timestamp do
    DateTime.utc_now()
    |> DateTime.to_unix()
    |> Integer.to_string()
  end
end

