defmodule Microkernel.Factory do
  use ExMachina.Ecto, repo: Microkernel.Repo

  alias Microkernel.Devices.Device

  def device_factory do
    %Device{
      name: sequence(:name, &"Device #{&1}"),
      device_id: sequence(:device_id, &"device-#{&1}"),
      status: "online",
      firmware_version: "1.0.0",
      last_seen: DateTime.utc_now(),
      metadata: %{}
    }
  end

  def offline_device_factory do
    struct!(
      device_factory(),
      %{
        status: "offline",
        last_seen: DateTime.add(DateTime.utc_now(), -3600, :second)
      }
    )
  end
end

