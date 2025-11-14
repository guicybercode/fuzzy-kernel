defmodule Microkernel.Telemetry.Reading do
  use Ecto.Schema
  import Ecto.Changeset
  alias Microkernel.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "telemetry_readings" do
    field :device_id, :string
    field :sensor_type, :string
    field :value, :float
    field :unit, :string
    field :anomaly, :boolean, default: false
    field :confidence, :float
    field :metadata, :map, default: %{}
    field :timestamp, :utc_datetime

    belongs_to :organization, Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [:device_id, :sensor_type, :value, :unit, :anomaly, :confidence, :metadata, :timestamp])
    |> validate_required([:device_id, :sensor_type, :value, :timestamp])
  end
end

