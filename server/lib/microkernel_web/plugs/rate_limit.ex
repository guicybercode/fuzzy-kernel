defmodule MicrokernelWeb.Plugs.RateLimit do
  import Plug.Conn
  require Logger

  @behaviour Plug

  def init(opts) do
    Keyword.get(opts, :max_requests, 100)
  end

  def call(conn, max_requests) do
    key = get_rate_limit_key(conn)
    
    case ExRated.check_rate(key, max_requests, 60_000) do
      {:ok, _} ->
        conn
      {:error, _} ->
        Logger.warning("Rate limit exceeded for #{key}")
        conn
        |> put_resp_header("x-ratelimit-limit", "#{max_requests}")
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> put_resp_header("retry-after", "60")
        |> put_status(429)
        |> Phoenix.Controller.json(%{error: "Rate limit exceeded"})
        |> halt()
    end
  end

  defp get_rate_limit_key(conn) do
    case get_req_header(conn, "authorization") do
      [token | _] -> "rate_limit:#{token}"
      _ -> "rate_limit:#{conn.remote_ip}"
    end
  end
end

