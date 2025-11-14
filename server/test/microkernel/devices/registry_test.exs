defmodule Microkernel.Devices.RegistryTest do
  use Microkernel.DataCase
  alias Microkernel.Devices.Registry
  alias Microkernel.Factory

  describe "register_device/2" do
    test "registers a new device" do
      assert {:ok, device} = Registry.register_device("device-001", %{name: "Test Device"})
      assert device.device_id == "device-001"
      assert device.name == "Test Device"
      assert device.status == "online"
    end

    test "updates existing device" do
      device = Factory.insert(:device, device_id: "device-001")
      assert {:ok, updated} = Registry.register_device("device-001", %{})
      assert updated.id == device.id
      assert updated.last_seen != device.last_seen
    end
  end

  describe "heartbeat/1" do
    test "updates device last_seen" do
      device = Factory.insert(:device, device_id: "device-001")
      old_seen = device.last_seen

      Process.sleep(10)
      Registry.heartbeat("device-001")

      updated = Registry.get_device("device-001")
      assert DateTime.compare(updated.last_seen, old_seen) == :gt
    end
  end

  describe "list_devices/0" do
    test "returns all devices" do
      Factory.insert_list(3, :device)
      devices = Registry.list_devices()
      assert length(devices) == 3
    end
  end
end

