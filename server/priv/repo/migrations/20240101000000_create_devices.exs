defmodule Microkernel.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :device_id, :string, null: false
      add :status, :string, default: "offline"
      add :firmware_version, :string
      add :last_seen, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:devices, [:device_id])
  end
end

