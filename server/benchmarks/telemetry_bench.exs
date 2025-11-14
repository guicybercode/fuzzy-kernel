defmodule TelemetryBench do
  use BencheeDsl

  job "record_telemetry" do
    fn ->
      Microkernel.Telemetry.record_telemetry("device-001", "temperature", 25.5, %{unit: "celsius"})
    end
  end

  job "get_readings" do
    setup do
      for i <- 1..100 do
        Microkernel.Telemetry.record_telemetry("device-001", "temperature", 20.0 + i)
      end
      Process.sleep(100)
      :ok
    end

    fn ->
      Microkernel.Telemetry.get_readings("device-001", limit: 50)
    end
  end
end

