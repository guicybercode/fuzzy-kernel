defmodule Microkernel.Alerts.Alert do
  use Ecto.Schema
  import Ecto.Changeset
  alias Microkernel.Devices.Device

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :string
  schema "alerts" do
    field :name, :string
    field :sensor_type, :string
    field :condition, :string
    field :threshold_value, :float
    field :enabled, :boolean, default: true
    field :webhook_url, :string
    field :last_triggered_at, :utc_datetime
    field :trigger_count, :integer, default: 0

    belongs_to :device, Device, foreign_key: :device_id, type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:name, :sensor_type, :condition, :threshold_value, :enabled, :webhook_url])
    |> validate_required([:name, :sensor_type, :condition, :threshold_value])
    |> validate_inclusion(:condition, ["gt", "lt", "gte", "lte", "eq"])
    |> validate_format(:webhook_url, ~r/^https?:\/\/.+/, message: "must be a valid URL")
  end

  def check_condition(alert, value) do
    case alert.condition do
      "gt" -> value > alert.threshold_value
      "lt" -> value < alert.threshold_value
      "gte" -> value >= alert.threshold_value
      "lte" -> value <= alert.threshold_value
      "eq" -> abs(value - alert.threshold_value) < 0.01
      _ -> false
    end
  end
end

