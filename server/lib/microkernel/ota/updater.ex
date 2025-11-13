defmodule Microkernel.OTA.Updater do
  use GenServer
  require Logger
  alias Microkernel.MQTT.Publisher

  defmodule Update do
    defstruct [
      :version,
      :package_url,
      :checksum,
      :release_notes,
      :released_at
    ]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{updates: %{}, deployments: %{}}}
  end

  def register_update(version, package_url, checksum, release_notes \\ "") do
    GenServer.call(__MODULE__, {:register_update, version, package_url, checksum, release_notes})
  end

  def deploy_update(device_id, version) do
    GenServer.call(__MODULE__, {:deploy_update, device_id, version})
  end

  def list_updates do
    GenServer.call(__MODULE__, :list_updates)
  end

  def get_deployment_status(device_id) do
    GenServer.call(__MODULE__, {:get_deployment_status, device_id})
  end

  @impl true
  def handle_call({:register_update, version, package_url, checksum, release_notes}, _from, state) do
    update = %Update{
      version: version,
      package_url: package_url,
      checksum: checksum,
      release_notes: release_notes,
      released_at: DateTime.utc_now()
    }

    new_state = put_in(state.updates[version], update)
    Logger.info("Registered OTA update: #{version}")

    {:reply, {:ok, update}, new_state}
  end

  @impl true
  def handle_call({:deploy_update, device_id, version}, _from, state) do
    case Map.get(state.updates, version) do
      nil ->
        {:reply, {:error, :version_not_found}, state}

      update ->
        case Publisher.request_update(device_id, version) do
          :ok ->
            deployment = %{
              device_id: device_id,
              version: version,
              status: :pending,
              started_at: DateTime.utc_now(),
              package_url: update.package_url,
              checksum: update.checksum
            }

            new_state = put_in(state.deployments[device_id], deployment)
            Logger.info("Initiated OTA update for #{device_id} to version #{version}")

            Phoenix.PubSub.broadcast(
              Microkernel.PubSub,
              "ota_updates",
              {:update_deployed, device_id, version}
            )

            {:reply, {:ok, deployment}, new_state}

          error ->
            {:reply, error, state}
        end
    end
  end

  @impl true
  def handle_call(:list_updates, _from, state) do
    updates = state.updates |> Map.values() |> Enum.sort_by(& &1.released_at, {:desc, DateTime})
    {:reply, updates, state}
  end

  @impl true
  def handle_call({:get_deployment_status, device_id}, _from, state) do
    deployment = Map.get(state.deployments, device_id)
    {:reply, deployment, state}
  end

  @impl true
  def handle_cast({:update_deployment_status, device_id, status}, state) do
    case Map.get(state.deployments, device_id) do
      nil ->
        {:noreply, state}

      deployment ->
        updated_deployment = %{deployment | status: status, completed_at: DateTime.utc_now()}
        new_state = put_in(state.deployments[device_id], updated_deployment)

        Phoenix.PubSub.broadcast(
          Microkernel.PubSub,
          "ota_updates",
          {:update_status_changed, device_id, status}
        )

        {:noreply, new_state}
    end
  end

  def update_deployment_status(device_id, status) do
    GenServer.cast(__MODULE__, {:update_deployment_status, device_id, status})
  end
end

