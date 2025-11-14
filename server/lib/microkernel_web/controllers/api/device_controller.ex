defmodule MicrokernelWeb.Api.DeviceController do
  use MicrokernelWeb, :controller
  alias Microkernel.Devices.Registry

  def index(conn, _params) do
    devices = Registry.list_devices()
    render(conn, :index, devices: devices)
  end

  def show(conn, %{"id" => device_id}) do
    case Registry.get_device(device_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "Device not found")

      device ->
        render(conn, :show, device: device)
    end
  end
end

