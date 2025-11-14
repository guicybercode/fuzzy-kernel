defmodule Microkernel.Jobs.OTAJobTest do
  use Microkernel.DataCase
  use Oban.Testing, repo: Microkernel.Repo
  alias Microkernel.Jobs.OTAJob

  describe "perform/1" do
    test "processes OTA update job" do
      device = insert(:device, device_id: "device-001")

      assert :ok = perform_job(OTAJob, %{device_id: device.device_id, version: "1.0.1"})
    end
  end
end

