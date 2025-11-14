defmodule MicrokernelWeb.MetricsController do
  use MicrokernelWeb, :controller

  def index(conn, _params) do
    metrics = Prometheus.Format.Text.format()
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end
end

