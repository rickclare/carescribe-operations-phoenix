import Config

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# Configure your database
config :operations, Operations.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "carescribe_operations_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  port: "DATABASE_PORT" |> System.get_env("5432") |> String.to_integer(),
  pool_size: 10

# Watch static and templates for browser reloading.
config :operations, OperationsWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg|webp|avif)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/operations_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :operations, OperationsWeb.Endpoint,
  url: [scheme: "https", host: System.get_env("PHX_HOST", "localhost")],
  http: [
    # Binding to loopback ipv4 address prevents access from other machines.
    # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
    ip: {127, 0, 0, 1},
    port: "PORT" |> System.get_env("4000") |> String.to_integer()
  ],
  https: [
    port: "SSL_PORT" |> System.get_env("4443") |> String.to_integer(),
    cipher_suite: :strong,
    certfile: "priv/cert/selfsigned.pem",
    keyfile: "priv/cert/selfsigned_key.pem"
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "5MN4vH0jJXMAhrz7bJZF9xR0mORTT4yXwT5q8iulw7FA4UgtQxcC/uzE6qcAYk8h",
  watchers: [
    bun: {Bun, :install_and_run, [:js, ~w(--sourcemap=external --watch)]},
    bun: {Bun, :install_and_run, [:css, ~w(--watch)]}
  ]

# Enable dev routes for dashboard and mailbox
config :operations, dev_routes: true

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :phoenix_live_view,
  # Include debug annotations and locations in rendered markup.
  # Changing this configuration will require mix clean and a full recompile.
  debug_heex_annotations: true,
  debug_attributes: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false
