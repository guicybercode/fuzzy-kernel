defmodule MicrokernelWeb.CoreComponents do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} phx-remove={hide_modal(@id)} class="relative z-50 hidden">
      <div class="fixed inset-0 bg-zinc-50/90 transition-opacity" />
      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <div class="bg-white shadow-lg rounded-lg p-6">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}")
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button class={"phx-submit-loading:opacity-75 rounded-lg bg-blue-600 hover:bg-blue-700 py-2 px-3 text-sm font-semibold leading-6 text-white active:text-white/80 #{@class}"}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <div
      :for={{kind, message} <- @flash}
      :if={message != nil}
      class={[
        "rounded-lg p-3 mb-4",
        kind == :info && "bg-blue-50 text-blue-800",
        kind == :error && "bg-red-50 text-red-800"
      ]}
      role="alert"
    >
      <p class="font-medium"><%= message %></p>
    </div>
    """
  end
end

