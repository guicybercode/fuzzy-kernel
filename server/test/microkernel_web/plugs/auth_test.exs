defmodule MicrokernelWeb.Plugs.AuthTest do
  use MicrokernelWeb.ConnCase
  alias Microkernel.Auth
  alias Microkernel.Auth.ApiKey

  setup %{conn: conn} do
    {:ok, key} = Auth.create_api_key("Test Key")
    {:ok, conn: conn, api_key: key}
  end

  describe "authentication" do
    test "allows request with valid API key", %{conn: conn, api_key: key} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{key}")
        |> MicrokernelWeb.Plugs.Auth.call([])

      refute conn.halted
    end

    test "rejects request without API key", %{conn: conn} do
      conn = MicrokernelWeb.Plugs.Auth.call(conn, [])

      assert conn.halted
      assert conn.status == 401
      assert %{"error" => "Missing API key"} = Jason.decode!(conn.resp_body)
    end

    test "rejects request with invalid API key", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_key")
        |> MicrokernelWeb.Plugs.Auth.call([])

      assert conn.halted
      assert conn.status == 401
      assert %{"error" => "Invalid API key"} = Jason.decode!(conn.resp_body)
    end

    test "rejects request with inactive API key", %{conn: conn, api_key: key} do
      {:ok, api_key} = Microkernel.Repo.get_by(ApiKey, key: key)
      {:ok, _} = Auth.deactivate_api_key(api_key.id)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{key}")
        |> MicrokernelWeb.Plugs.Auth.call([])

      assert conn.halted
      assert conn.status == 401
    end
  end
end

