defmodule MicrokernelWeb.Api.OTAView do
  use MicrokernelWeb, :view

  def render("show.json", %{deployment: deployment}) do
    %{
      data: %{
        device_id: deployment.device_id,
        version: deployment.version,
        status: deployment.status,
        package_url: deployment.package_url,
        checksum: deployment.checksum,
        started_at: deployment.started_at,
        completed_at: deployment.completed_at
      }
    }
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end
end

