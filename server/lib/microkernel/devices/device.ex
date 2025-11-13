defmodule Microkernel.Devices.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "devices" do
    field :name, :string
    field :device_id, :string
    field :status, :string, default: "offline"
    field :firmware_version, :string
    field :last_seen, :utc_datetime
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:name, :device_id, :status, :firmware_version, :last_seen, :metadata])
    |> validate_required([:device_id])
    |> unique_constraint(:device_id)
  end

  def update_last_seen(device) do
    changeset(device, %{last_seen: DateTime.utc_now(), status: "online"})
  end
end

