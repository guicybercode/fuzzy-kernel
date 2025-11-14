defmodule MicrokernelWeb.AuthController do
  use MicrokernelWeb, :controller
  alias Microkernel.Users

  def login(conn, %{"email" => email, "password" => password}) do
    case Users.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Logged in successfully")
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> redirect(to: ~p"/login")
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/login")
  end
end

