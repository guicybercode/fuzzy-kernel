defmodule MicrokernelWeb.Api.TelemetryView do
  use MicrokernelWeb, :view

  def render("index.json", %{readings: readings}) do
    %{data: render_many(readings, __MODULE__, "reading.json")}
  end

  def render("show.json", %{reading: reading}) do
    %{data: render_one(reading, __MODULE__, "reading.json")}
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

