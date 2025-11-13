import Config

config :microkernel, Microkernel.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "microkernel_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :microkernel, MicrokernelWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "microkernel_dev_secret_key_base_change_me_in_production_long_string",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

config :microkernel, MicrokernelWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/microkernel_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :microkernel, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :microkernel, :mqtt,
  host: "localhost",
  port: 1883,
  client_id: "microkernel_server"

