defmodule Microkernel do
  @moduledoc """
  Distributed IoT Microkernel Platform

  A high-performance IoT platform combining Zig for edge computing
  and Elixir for server orchestration.

  ## Features

  - Real-time device monitoring
  - MQTT/CoAP communication
  - OTA firmware updates
  - TinyML anomaly detection
  - WebAssembly edge scripting

  ## Usage

      iex> Microkernel.Devices.Registry.list_devices()
      [%Device{}, ...]

  """

  @doc """
  Returns the application version.
  """
  def version do
    Application.spec(:microkernel, :vsn)
    |> to_string()
  end
end

