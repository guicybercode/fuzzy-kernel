defmodule Microkernel.Repo.Migrations.CreateTelemetry do
  use Ecto.Migration

  def change do
    create table(:telemetry, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_id, :string, null: false
      add :sensor_type, :string, null: false
      add :value, :float, null: false
      add :unit, :string
      add :anomaly, :boolean, default: false
      add :confidence, :float
      add :metadata, :map, default: %{}
      add :timestamp, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:telemetry, [:device_id])
    create index(:telemetry, [:timestamp])
    create index(:telemetry, [:sensor_type])
    create index(:telemetry, [:device_id, :timestamp])
    create index(:telemetry, [:anomaly])
  end
end

