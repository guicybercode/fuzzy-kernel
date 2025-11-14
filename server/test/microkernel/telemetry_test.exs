defmodule Microkernel.TelemetryTest do
  use Microkernel.DataCase
  alias Microkernel.Telemetry

  describe "record_telemetry/4" do
    test "saves telemetry reading to database" do
      Telemetry.record_telemetry("device-001", "temperature", 25.5, %{unit: "celsius"})

      Process.sleep(100)

      readings = Telemetry.get_readings("device-001")
      assert length(readings) == 1
      assert hd(readings).device_id == "device-001"
      assert hd(readings).sensor_type == "temperature"
      assert hd(readings).value == 25.5
    end
  end

  describe "get_readings/2" do
    test "returns readings for device" do
      Telemetry.record_telemetry("device-001", "temperature", 25.0)
      Telemetry.record_telemetry("device-001", "humidity", 60.0)
      Telemetry.record_telemetry("device-002", "temperature", 30.0)

      Process.sleep(100)

      readings = Telemetry.get_readings("device-001")
      assert length(readings) == 2
    end

    test "filters by sensor_type" do
      Telemetry.record_telemetry("device-001", "temperature", 25.0)
      Telemetry.record_telemetry("device-001", "humidity", 60.0)

      Process.sleep(100)

      readings = Telemetry.get_readings("device-001", sensor_type: "temperature")
      assert length(readings) == 1
      assert hd(readings).sensor_type == "temperature"
    end

    test "respects limit" do
      for i <- 1..10 do
        Telemetry.record_telemetry("device-001", "temperature", 20.0 + i)
      end

      Process.sleep(100)

      readings = Telemetry.get_readings("device-001", limit: 5)
      assert length(readings) == 5
    end
  end

  describe "get_latest_reading/2" do
    test "returns latest reading for device" do
      Telemetry.record_telemetry("device-001", "temperature", 25.0)
      Process.sleep(10)
      Telemetry.record_telemetry("device-001", "temperature", 30.0)

      Process.sleep(100)

      reading = Telemetry.get_latest_reading("device-001", "temperature")
      assert reading.value == 30.0
    end
  end
end

