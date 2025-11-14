defmodule Microkernel.Prometheus do
  @moduledoc """
  Prometheus metrics setup
  """
  use Prometheus.PlugExporter

  def init_metrics do
    Prometheus.Registry.register_collector(:prometheus_process_collector)
    Prometheus.Registry.register_collector(:prometheus_mnesia_collector)
    :ok
  end
end

