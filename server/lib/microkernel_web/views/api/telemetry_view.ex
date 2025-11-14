defmodule MicrokernelWeb.Api.TelemetryView do
  use MicrokernelWeb, :view

  def render("index.json", %{readings: readings}) do
    %{data: Enum.map(readings, &render("reading.json", %{reading: &1}))}
  end

  def render("show.json", %{reading: reading}) do
    %{data: render("reading.json", %{reading: reading})}
  end

  def render("reading.json", %{reading: reading}) do
    %{
      id: reading.id,
      device_id: reading.device_id,
      sensor_type: reading.sensor_type,
      value: reading.value,
      unit: reading.unit,
      anomaly: reading.anomaly,
      confidence: reading.confidence,
      metadata: reading.metadata,
      timestamp: reading.timestamp,
      inserted_at: reading.inserted_at
    }
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end
end

