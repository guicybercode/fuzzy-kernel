defmodule MicrokernelWeb.Api.DeviceView do
  use MicrokernelWeb, :view

  def render("index.json", %{devices: devices}) do
    %{data: Enum.map(devices, &render("device.json", %{device: &1}))}
  end

  def render("show.json", %{device: device}) do
    %{data: render("device.json", %{device: device})}
  end

  def render("device.json", %{device: device}) do
    %{
      id: device.id,
      device_id: device.device_id,
      name: device.name,
      status: device.status,
      firmware_version: device.firmware_version,
      last_seen: device.last_seen,
      metadata: device.metadata,
      inserted_at: device.inserted_at,
      updated_at: device.updated_at
    }
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end
end

