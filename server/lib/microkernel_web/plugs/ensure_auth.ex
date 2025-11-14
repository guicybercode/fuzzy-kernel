defmodule MicrokernelWeb.Plugs.EnsureAuth do
  import Plug.Conn
  import Phoenix.Controller
  alias Microkernel.Users.User

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in")
        |> redirect(to: ~p"/login")
        |> halt()

      user_id ->
        assign(conn, :current_user, Microkernel.Users.get_user!(user_id))
    end
  end
end

