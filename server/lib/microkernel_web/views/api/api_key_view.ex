defmodule MicrokernelWeb.Api.ApiKeyView do
  use MicrokernelWeb, :view

  def render("index.json", %{keys: keys}) do
    %{data: render_many(keys, __MODULE__, "api_key.json")}
  end

  def render("show.json", %{key: key, name: name}) do
    %{
      data: %{
        key: key,
        name: name,
        message: "Save this key - it will not be shown again"
      }
    }
  end

  def render("api_key.json", %{api_key: api_key}) do
    %{
      id: api_key.id,
      name: api_key.name,
      active: api_key.active,
      last_used_at: api_key.last_used_at,
      inserted_at: api_key.inserted_at
    }
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end
end

