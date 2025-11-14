defmodule Microkernel.MixProject do
  use Mix.Project

  def project do
    [
      app: :microkernel,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      description: "Distributed IoT Microkernel Platform - Zig edge + Elixir server",
      package: [
        maintainers: ["Microkernel Team"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/guicybercode/fuzzy-kernel"}
      ],
      docs: [
        main: "Microkernel",
        extras: ["README.md"],
        groups_for_extras: [
          "Getting Started": ~r/docs\/getting_started/,
          "Guides": ~r/docs\/guides/
        ]
      ]
    ]
  end

  def application do
    [
      mod: {Microkernel.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 0.20.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"},
      {:emqtt, "~> 1.8"},
      {:quicer, "~> 0.0", optional: true},
      {:snabbkaffe, "~> 1.0", optional: true},
      {:finch, "~> 0.16"},
      {:mox, "~> 1.0", only: :test},
      {:bypass, "~> 2.1", only: :test},
      {:ex_machina, "~> 2.7", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:oban, "~> 2.17"},
      {:timex, "~> 3.7"},
      {:prometheus_ex, "~> 3.1"},
      {:prometheus_plugs, "~> 1.1"},
      {:prometheus_ecto, "~> 1.1"},
      {:open_api_spex, "~> 3.18"},
      {:sentry, "~> 9.0"},
      {:logger_json, "~> 5.0"},
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_html, "~> 1.0", only: :dev}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "test.watch": ["test.watch --stale"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      quality: ["credo --strict", "dialyzer", "test"],
      "format.check": ["format --check-formatted"],
      "bench": ["run benchmarks/telemetry_bench.exs", "run benchmarks/device_registry_bench.exs"]
    ]
  end
end

