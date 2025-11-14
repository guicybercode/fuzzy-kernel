defmodule Microkernel.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Microkernel.Repo,
      {DNSCluster, query: Application.get_env(:microkernel, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Microkernel.PubSub},
      {Finch, name: Microkernel.Finch},
      MicrokernelWeb.Endpoint,
      {Microkernel.Devices.Supervisor, []},
      {Microkernel.MQTT.Subscriber, []},
      {Microkernel.Telemetry, []},
      {Microkernel.OTA.Updater, []},
      Oban
    ]

    opts = [strategy: :one_for_one, name: Microkernel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MicrokernelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

