defmodule MicrokernelWeb.Plugs.ErrorHandler do
  @moduledoc """
  Plug para capturar e reportar erros para o Sentry
  """
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    register_before_send(conn, &capture_errors/1)
  end

  defp capture_errors(conn) do
    if conn.status >= 500 do
      Sentry.capture_exception(
        %RuntimeError{message: "HTTP #{conn.status} error"},
        [
          request: %{
            url: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
            method: conn.method,
            query_string: conn.query_string,
            headers: format_headers(conn.req_headers)
          },
          user: %{
            ip_address: get_remote_ip(conn)
          }
        ]
      )
    end

    conn
  end

  defp format_headers(headers) do
    Enum.into(headers, %{})
  end

  defp get_remote_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end
end

