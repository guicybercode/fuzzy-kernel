defmodule MicrokernelWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      import MicrokernelWeb.Router.Helpers
      import Microkernel.Factory
    end
  end

  setup tags do
    Microkernel.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

