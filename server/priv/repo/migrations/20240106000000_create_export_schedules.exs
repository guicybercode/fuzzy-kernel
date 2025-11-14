defmodule Microkernel.Repo.Migrations.CreateExportSchedules do
  use Ecto.Migration

  def change do
    create table(:export_schedules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_id, :string
      add :format, :string, null: false
      add :schedule, :string, null: false
      add :destination, :string
      add :active, :boolean, default: true
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:export_schedules, [:device_id])
    create index(:export_schedules, [:organization_id])
    create index(:export_schedules, [:active])
  end
end

