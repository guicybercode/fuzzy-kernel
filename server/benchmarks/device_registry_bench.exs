defmodule DeviceRegistryBench do
  use BencheeDsl

  job "register_device" do
    fn ->
      device_id = "device-#{:rand.uniform(100000)}"
      Microkernel.Devices.Registry.register_device(device_id, %{name: "Test Device"})
    end
  end

  job "get_device" do
    setup do
      {:ok, device} = Microkernel.Devices.Registry.register_device("device-001", %{name: "Test"})
      device
    end

    fn device ->
      Microkernel.Devices.Registry.get_device(device.device_id)
    end
  end

  job "list_devices" do
    setup do
      for i <- 1..100 do
        Microkernel.Devices.Registry.register_device("device-#{i}", %{name: "Device #{i}"})
      end
      :ok
    end

    fn ->
      Microkernel.Devices.Registry.list_devices()
    end
  end
end

