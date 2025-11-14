defmodule MicrokernelWeb.Api.ApiKeyController do
  use MicrokernelWeb, :controller
  alias Microkernel.Auth

  def create(conn, %{"name" => name}) do
    case Auth.create_api_key(name) do
      {:ok, key} ->
        render(conn, :show, %{key: key, name: name})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "Failed to create API key: #{inspect(changeset.errors)}")
    end
  end

  def create(conn, _params) do
    case Auth.create_api_key() do
      {:ok, key} ->
        render(conn, :show, %{key: key, name: "Default API Key"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "Failed to create API key: #{inspect(changeset.errors)}")
    end
  end

  def index(conn, _params) do
    keys = Auth.list_api_keys()
    render(conn, :index, keys: keys)
  end
end

