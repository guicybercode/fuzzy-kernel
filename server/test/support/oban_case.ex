defmodule Microkernel.ObanCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto.Query
      import Microkernel.Factory
    end
  end

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Microkernel.Repo)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.checkin(Microkernel.Repo)
    end)

    :ok
  end
end

