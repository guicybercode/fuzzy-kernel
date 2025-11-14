defmodule MicrokernelWeb.Api.OTAController do
  use MicrokernelWeb, :controller
  alias Microkernel.OTA.Updater
  alias Microkernel.Devices.Registry

  def create(conn, %{"device_id" => device_id, "version" => version}) do
    case Registry.get_device(device_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "Device not found")

      _device ->
        case Updater.deploy_update(device_id, version) do
          {:ok, deployment} ->
            render(conn, :show, deployment: deployment)

          {:error, :version_not_found} ->
            conn
            |> put_status(:not_found)
            |> render(:error, message: "Firmware version not found")

          {:error, reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(:error, message: "Failed to deploy update: #{inspect(reason)}")
        end
    end
  end

  def status(conn, %{"device_id" => device_id}) do
    case Updater.get_deployment_status(device_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "No deployment found")

      deployment ->
        render(conn, :show, deployment: deployment)
    end
  end
end

