import Config

config :microkernel, MicrokernelWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "localhost", port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :remote_ip]

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "production"
  },
  included_environments: [:prod]

config :logger_json, :backend,
  formatter: LoggerJSON.Formatters.BasicLogger,
  metadata: [:request_id, :remote_ip, :user_id, :device_id]

import_config "prod.secret.exs"

