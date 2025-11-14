defmodule MicrokernelWeb.Api.DeviceControllerTest do
  use MicrokernelWeb.ConnCase
  alias Microkernel.Auth
  alias Microkernel.Devices.Registry

  setup %{conn: conn} do
    {:ok, api_key} = Auth.create_api_key("Test Key")
    conn = put_req_header(conn, "authorization", "Bearer #{api_key}")
    {:ok, conn: conn, api_key: api_key}
  end

  describe "GET /api/devices" do
    test "lists all devices", %{conn: conn} do
      {:ok, device1} = Registry.register_device("device-001", %{name: "Device 1"})
      {:ok, device2} = Registry.register_device("device-002", %{name: "Device 2"})

      conn = get(conn, ~p"/api/devices")
      assert %{"data" => devices} = json_response(conn, 200)
      assert length(devices) == 2
    end

    test "requires authentication", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> get(~p"/api/devices")

      assert json_response(conn, 401)
    end
  end

  describe "GET /api/devices/:id" do
    test "shows device", %{conn: conn} do
      {:ok, device} = Registry.register_device("device-001", %{name: "Test Device"})

      conn = get(conn, ~p"/api/devices/#{device.id}")
      assert %{"data" => device_data} = json_response(conn, 200)
      assert device_data["device_id"] == "device-001"
      assert device_data["name"] == "Test Device"
    end

    test "returns 404 for non-existent device", %{conn: conn} do
      conn = get(conn, ~p"/api/devices/999")
      assert json_response(conn, 404)
    end
  end
end

