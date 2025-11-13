defmodule Microkernel.Repo do
  use Ecto.Repo,
    otp_app: :microkernel,
    adapter: Ecto.Adapters.Postgres
end

