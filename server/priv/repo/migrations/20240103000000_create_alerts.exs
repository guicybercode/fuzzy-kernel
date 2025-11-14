defmodule Microkernel.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_id, references(:devices, type: :string, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :sensor_type, :string, null: false
      add :condition, :string, null: false
      add :threshold_value, :float, null: false
      add :enabled, :boolean, default: true, null: false
      add :webhook_url, :string
      add :last_triggered_at, :utc_datetime
      add :trigger_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:alerts, [:device_id])
    create index(:alerts, [:enabled])
    create index(:alerts, [:sensor_type])
  end
end

