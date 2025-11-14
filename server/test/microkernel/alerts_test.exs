defmodule Microkernel.AlertsTest do
  use Microkernel.DataCase
  alias Microkernel.Alerts
  alias Microkernel.Alerts.Alert

  describe "create_alert/1" do
    test "creates an alert with valid attributes" do
      device = insert(:device)
      
      attrs = %{
        device_id: device.device_id,
        name: "High Temperature",
        sensor_type: "temperature",
        condition: "gt",
        threshold_value: 30.0,
        enabled: true
      }

      assert {:ok, alert} = Alerts.create_alert(attrs)
      assert alert.name == "High Temperature"
      assert alert.sensor_type == "temperature"
      assert alert.threshold_value == 30.0
    end

    test "validates required fields" do
      assert {:error, changeset} = Alerts.create_alert(%{})
      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "check_condition/2" do
    test "checks gt condition" do
      alert = %Alert{condition: "gt", threshold_value: 30.0}
      assert Alert.check_condition(alert, 35.0) == true
      assert Alert.check_condition(alert, 25.0) == false
    end

    test "checks lt condition" do
      alert = %Alert{condition: "lt", threshold_value: 30.0}
      assert Alert.check_condition(alert, 25.0) == true
      assert Alert.check_condition(alert, 35.0) == false
    end
  end
end

