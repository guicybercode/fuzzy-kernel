defmodule MicrokernelWeb.Plugs.Auth do
  import Plug.Conn
  import Ecto.Query
  require Logger
  alias Microkernel.Repo
  alias Microkernel.Auth.ApiKey

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> api_key] ->
        case validate_api_key(api_key) do
          {:ok, _key} ->
            conn

          {:error, reason} ->
            Logger.warning("API key validation failed: #{reason}")
            conn
            |> put_status(:unauthorized)
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{error: "Invalid API key"}))
            |> halt()
        end

      _ ->
        conn
        |> put_status(:unauthorized)
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Missing API key"}))
        |> halt()
    end
  end

  defp validate_api_key(key) do
    case Repo.get_by(ApiKey, key: key, active: true) do
      nil ->
        {:error, :not_found}

      api_key ->
        Repo.update_all(
          from(ak in ApiKey, where: ak.id == ^api_key.id),
          set: [last_used_at: DateTime.utc_now()]
        )
        {:ok, api_key}
    end
  end
end

