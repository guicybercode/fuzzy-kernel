defmodule MicrokernelWeb.Api.TelemetryController do
  use MicrokernelWeb, :controller
  alias Microkernel.Telemetry

  def index(conn, %{"device_id" => device_id} = params) do
    limit = params["limit"] |> parse_limit()
    since = params["since"] |> parse_since()
    sensor_type = params["sensor_type"]

    readings = Telemetry.get_readings(device_id, limit: limit, since: since, sensor_type: sensor_type)
    render(conn, :index, readings: readings)
  end

  def latest(conn, %{"device_id" => device_id} = params) do
    sensor_type = params["sensor_type"]
    reading = Telemetry.get_latest_reading(device_id, sensor_type)

    case reading do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "No readings found")

      reading ->
        render(conn, :show, reading: reading)
    end
  end

  defp parse_limit(nil), do: 100
  defp parse_limit(limit) when is_binary(limit), do: String.to_integer(limit)
  defp parse_limit(limit), do: limit

  defp parse_since(nil), do: nil
  defp parse_since(since) when is_binary(since) do
    case DateTime.from_iso8601(since) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_since(since), do: since
end

