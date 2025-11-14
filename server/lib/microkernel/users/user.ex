defmodule Microkernel.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Microkernel.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :name, :string
    field :role, :string, default: "user"
    field :active, :boolean, default: true
    belongs_to :organization, Organization

    timestamps(type: :utc_datetime)
  end

  @roles ["admin", "user", "viewer"]

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role, :active, :organization_id])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:email)
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
      _ ->
        changeset
    end
  rescue
    _ -> changeset
  end
end

