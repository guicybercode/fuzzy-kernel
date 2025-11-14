defmodule Microkernel.Auth do
  import Ecto.Query
  alias Microkernel.Repo
  alias Microkernel.Auth.ApiKey

  def create_api_key(name \\ "Default API Key") do
    key = ApiKey.generate_key()
    
    attrs = %{
      key: key,
      name: name,
      active: true
    }

    case Repo.insert(ApiKey.changeset(%ApiKey{}, attrs)) do
      {:ok, api_key} -> {:ok, api_key.key}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def list_api_keys do
    Repo.all(from ak in ApiKey, order_by: [desc: ak.inserted_at])
  end

  def deactivate_api_key(key_id) do
    case Repo.get(ApiKey, key_id) do
      nil -> {:error, :not_found}
      api_key -> Repo.update(ApiKey.changeset(api_key, %{active: false}))
    end
  end
end

