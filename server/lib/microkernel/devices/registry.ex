defmodule Microkernel.Devices.Registry do
  use GenServer
  require Logger
  alias Microkernel.Repo
  alias Microkernel.Devices.Device
  import Ecto.Query

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_heartbeat_check()
    {:ok, %{devices: %{}}}
  end

  def register_device(device_id, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:register, device_id, metadata})
  end

  def update_device_status(device_id, status) do
    GenServer.cast(__MODULE__, {:update_status, device_id, status})
  end

  def heartbeat(device_id) do
    GenServer.cast(__MODULE__, {:heartbeat, device_id})
  end

  def get_device(device_id) do
    GenServer.call(__MODULE__, {:get_device, device_id})
  end

  def list_devices do
    GenServer.call(__MODULE__, :list_devices)
  end

  @impl true
  def handle_call({:register, device_id, metadata}, _from, state) do
    case Repo.get_by(Device, device_id: device_id) do
      nil ->
        attrs = %{
          device_id: device_id,
          name: metadata[:name] || device_id,
          status: "online",
          firmware_version: metadata[:firmware_version] || "unknown",
          last_seen: DateTime.utc_now(),
          metadata: metadata
        }

        case Repo.insert(Device.changeset(%Device{}, attrs)) do
          {:ok, device} ->
            new_state = put_in(state.devices[device_id], %{last_seen: DateTime.utc_now()})
            Phoenix.PubSub.broadcast(Microkernel.PubSub, "devices", {:device_registered, device})
            {:reply, {:ok, device}, new_state}

          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end

      device ->
        device
        |> Device.update_last_seen()
        |> Repo.update()

        new_state = put_in(state.devices[device_id], %{last_seen: DateTime.utc_now()})
        Phoenix.PubSub.broadcast(Microkernel.PubSub, "devices", {:device_updated, device})
        {:reply, {:ok, device}, new_state}
    end
  end

  @impl true
  def handle_call({:get_device, device_id}, _from, state) do
    device = Repo.get_by(Device, device_id: device_id)
    {:reply, device, state}
  end

  @impl true
  def handle_call(:list_devices, _from, state) do
    devices = Repo.all(from d in Device, order_by: [desc: d.last_seen])
    {:reply, devices, state}
  end

  @impl true
  def handle_cast({:update_status, device_id, status}, state) do
    case Repo.get_by(Device, device_id: device_id) do
      nil ->
        {:noreply, state}

      device ->
        device
        |> Device.changeset(%{status: status})
        |> Repo.update()

        Phoenix.PubSub.broadcast(Microkernel.PubSub, "devices", {:device_status_changed, device_id, status})
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:heartbeat, device_id}, state) do
    case Repo.get_by(Device, device_id: device_id) do
      nil ->
        {:noreply, state}

      device ->
        device
        |> Device.update_last_seen()
        |> Repo.update()

        new_state = put_in(state.devices[device_id], %{last_seen: DateTime.utc_now()})
        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(:check_heartbeats, state) do
    now = DateTime.utc_now()
    timeout_seconds = 60

    Enum.each(state.devices, fn {device_id, device_state} ->
      diff = DateTime.diff(now, device_state.last_seen, :second)

      if diff > timeout_seconds do
        update_device_status(device_id, "offline")
      end
    end)

    schedule_heartbeat_check()
    {:noreply, state}
  end

  defp schedule_heartbeat_check do
    Process.send_after(self(), :check_heartbeats, 30_000)
  end
end

