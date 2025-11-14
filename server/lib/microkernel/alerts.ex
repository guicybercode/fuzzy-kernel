defmodule Microkernel.Alerts do
  use GenServer
  require Logger
  import Ecto.Query
  alias Microkernel.Repo
  alias Microkernel.Alerts.Alert
  alias Microkernel.Finch

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  def check_telemetry(device_id, sensor_type, value) do
    GenServer.cast(__MODULE__, {:check_telemetry, device_id, sensor_type, value})
  end

  def check_prometheus_metrics(metric_name, value, threshold, condition) do
    GenServer.cast(__MODULE__, {:check_metrics, metric_name, value, threshold, condition})
  end

  @impl true
  def handle_cast({:check_telemetry, device_id, sensor_type, value}, state) do
    alerts = Repo.all(
      from a in Alert,
      where: a.device_id == ^device_id,
      where: a.sensor_type == ^sensor_type,
      where: a.enabled == true
    )

    Enum.each(alerts, fn alert ->
      if Alert.check_condition(alert, value) do
        trigger_alert(alert, device_id, sensor_type, value)
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:check_metrics, metric_name, value, threshold, condition}, state) do
    alerts = Repo.all(
      from a in Alert,
      where: a.sensor_type == ^metric_name,
      where: a.enabled == true
    )

    Enum.each(alerts, fn alert ->
      if Alert.check_condition(alert, value) do
        trigger_metric_alert(alert, metric_name, value)
      end
    end)

    {:noreply, state}
  end

  defp trigger_alert(alert, device_id, sensor_type, value) do
    Logger.warning("Alert triggered: #{alert.name} for device #{device_id}")
    
    attrs = %{
      last_triggered_at: DateTime.utc_now(),
      trigger_count: alert.trigger_count + 1
    }

    case Repo.update(Alert.changeset(alert, attrs)) do
      {:ok, _} ->
        Phoenix.PubSub.broadcast(
          Microkernel.PubSub,
          "alerts:#{device_id}",
          {:alert_triggered, %{
            alert_id: alert.id,
            name: alert.name,
            device_id: device_id,
            sensor_type: sensor_type,
            value: value,
            threshold: alert.threshold_value,
            condition: alert.condition
          }}
        )

        if alert.webhook_url do
          send_webhook(alert, device_id, sensor_type, value)
        end
      {:error, _} ->
        :ok
    end
  end

  defp trigger_metric_alert(alert, metric_name, value) do
    Logger.warning("Metric alert triggered: #{alert.name} for metric #{metric_name}")
    
    attrs = %{
      last_triggered_at: DateTime.utc_now(),
      trigger_count: alert.trigger_count + 1
    }

    case Repo.update(Alert.changeset(alert, attrs)) do
      {:ok, _} ->
        Phoenix.PubSub.broadcast(
          Microkernel.PubSub,
          "alerts:metrics",
          {:metric_alert_triggered, %{
            alert_id: alert.id,
            name: alert.name,
            metric_name: metric_name,
            value: value,
            threshold: alert.threshold_value,
            condition: alert.condition
          }}
        )

        if alert.webhook_url do
          send_webhook(alert, nil, metric_name, value)
        end
      {:error, _} ->
        :ok
    end
  end

  defp send_webhook(alert, device_id, sensor_type, value) do
    payload = %{
      alert_id: alert.id,
      alert_name: alert.name,
      device_id: device_id,
      sensor_type: sensor_type,
      value: value,
      threshold: alert.threshold_value,
      condition: alert.condition,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Task.start(fn ->
      request = Finch.build(:post, alert.webhook_url, [{"Content-Type", "application/json"}], Jason.encode!(payload))
      case Finch.request(request, Microkernel.Finch) do
        {:ok, %{status: status}} when status in 200..299 ->
          Logger.info("Webhook sent successfully for alert #{alert.id}")
        {:ok, %{status: status}} ->
          Logger.warning("Webhook returned status #{status} for alert #{alert.id}")
        {:error, reason} ->
          Logger.error("Webhook failed for alert #{alert.id}: #{inspect(reason)}")
      end
    end)
  end

  def list_alerts(device_id \\ nil) do
    query = from a in Alert, order_by: [desc: a.inserted_at]
    query = if device_id, do: from(a in query, where: a.device_id == ^device_id), else: query
    Repo.all(query)
  end

  def create_alert(attrs) do
    %Alert{}
    |> Alert.changeset(attrs)
    |> Repo.insert()
  end

  def update_alert(alert, attrs) do
    alert
    |> Alert.changeset(attrs)
    |> Repo.update()
  end

  def delete_alert(alert) do
    Repo.delete(alert)
  end
end

