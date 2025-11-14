defmodule Microkernel.Exports.ExportSchedule do
  use Ecto.Schema
  import Ecto.Changeset
  alias Microkernel.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "export_schedules" do
    field :device_id, :string
    field :format, :string
    field :schedule, :string
    field :destination, :string
    field :active, :boolean, default: true
    belongs_to :organization, Organization

    timestamps(type: :utc_datetime)
  end

  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:device_id, :format, :schedule, :destination, :active, :organization_id])
    |> validate_required([:format, :schedule])
    |> validate_inclusion(:format, ["csv", "json"])
  end
end

