defmodule MicrokernelWeb.Api.OrganizationView do
  use MicrokernelWeb, :view

  def render("index.json", %{organizations: organizations}) do
    %{data: Enum.map(organizations, &render("organization.json", %{organization: &1}))}
  end

  def render("show.json", %{organization: organization}) do
    %{data: render("organization.json", %{organization: organization})}
  end

  def render("organization.json", %{organization: organization}) do
    %{
      id: organization.id,
      name: organization.name,
      slug: organization.slug,
      metadata: organization.metadata,
      inserted_at: organization.inserted_at,
      updated_at: organization.updated_at
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end

