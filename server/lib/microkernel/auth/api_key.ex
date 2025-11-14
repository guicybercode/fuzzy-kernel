defmodule Microkernel.Auth.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "api_keys" do
    field :key, :string
    field :name, :string
    field :active, :boolean, default: true
    field :last_used_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:key, :name, :active, :last_used_at])
    |> validate_required([:key])
    |> unique_constraint(:key)
  end

  def generate_key do
    :crypto.strong_rand_bytes(32)
    |> Base.encode64()
    |> String.replace(~r/[^A-Za-z0-9]/, "")
    |> String.slice(0, 32)
  end
end

