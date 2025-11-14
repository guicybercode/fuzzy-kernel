defmodule Microkernel.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset
  alias Microkernel.Devices.Device
  alias Microkernel.Telemetry.Reading
  alias Microkernel.Alerts.Alert

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :metadata, :map, default: %{}

    has_many :devices, Device
    has_many :telemetry_readings, Reading
    has_many :alerts, Alert

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :slug, :metadata])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "must be lowercase alphanumeric with hyphens")
    |> unique_constraint(:slug)
  end
end

