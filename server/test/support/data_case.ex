defmodule Microkernel.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Microkernel.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Microkernel.Factory
    end
  end

  setup tags do
    Microkernel.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Microkernel.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end

