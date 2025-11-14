defmodule Microkernel.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:slug])

    alter table(:devices) do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)
    end

    alter table(:telemetry_readings) do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)
    end

    alter table(:alerts) do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)
    end

    create index(:devices, [:organization_id])
    create index(:telemetry_readings, [:organization_id])
    create index(:alerts, [:organization_id])
  end
end

