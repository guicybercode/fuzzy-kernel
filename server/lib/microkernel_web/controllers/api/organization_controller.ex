defmodule MicrokernelWeb.Api.OrganizationController do
  use MicrokernelWeb, :controller
  alias Microkernel.Organizations

  def index(conn, _params) do
    organizations = Organizations.list_organizations()
    render(conn, :index, organizations: organizations)
  end

  def show(conn, %{"id" => id}) do
    organization = Organizations.get_organization!(id)
    render(conn, :show, organization: organization)
  end

  def create(conn, %{"organization" => org_params}) do
    case Organizations.create_organization(org_params) do
      {:ok, organization} ->
        conn
        |> put_status(:created)
        |> render(:show, organization: organization)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end
end

