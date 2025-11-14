defmodule MicrokernelWeb.Plugs.Authorize do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, roles: allowed_roles) do
    user = conn.assigns[:current_user]

    if user && user.role in allowed_roles do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> put_view(MicrokernelWeb.ErrorHTML)
      |> render(:"403")
      |> halt()
    end
  end
end

