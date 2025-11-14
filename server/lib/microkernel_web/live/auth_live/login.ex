defmodule MicrokernelWeb.AuthLive.Login do
  use MicrokernelWeb, :live_view

  def mount(_params, session, socket) do
    if session["user_id"] do
      {:ok, redirect(socket, to: ~p"/")}
    else
      {:ok, assign(socket, email: "", password: "", error: nil)}
    end
  end

  def handle_event("login", %{"email" => email, "password" => password}, socket) do
    case Microkernel.Users.authenticate_user(email, password) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Logged in successfully")
         |> push_navigate(to: ~p"/login?user_id=#{user.id}")}

      {:error, _reason} ->
        {:noreply, assign(socket, error: "Invalid email or password")}
    end
  end

  def handle_params(%{"user_id" => user_id}, _uri, socket) when is_binary(user_id) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to Microkernel
          </h2>
        </div>
        <form phx-submit="login" class="mt-8 space-y-6">
          <div class="rounded-md shadow-sm -space-y-px">
            <div>
              <input
                type="email"
                name="email"
                value={@email}
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
              />
            </div>
            <div>
              <input
                type="password"
                name="password"
                value={@password}
                required
                class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password"
              />
            </div>
          </div>

          <%= if @error do %>
            <div class="text-red-600 text-sm"><%= @error %></div>
          <% end %>

          <div>
            <button
              type="submit"
              class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Sign in
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end

