defmodule Microkernel.Users do
  import Ecto.Query
  alias Microkernel.Repo
  alias Microkernel.Users.User

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) do
    Repo.get_by(User, email: email, active: true)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def authenticate_user(email, password) do
    user = get_user_by_email(email)
    
    if user && Argon2.verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end

  def list_users(organization_id \\ nil) do
    query = from u in User, order_by: [desc: u.inserted_at]
    query = if organization_id, do: from(u in query, where: u.organization_id == ^organization_id), else: query
    Repo.all(query)
  end

  def update_user_role(user, role) do
    user
    |> User.changeset(%{role: role})
    |> Repo.update()
  end
end

