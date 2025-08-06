import Config

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :operations, Operations.Mailer, adapter: Swoosh.Adapters.Test

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :operations, Operations.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "carescribe_operations_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: "DATABASE_PORT" |> System.get_env("5432") |> String.to_integer(),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :operations, OperationsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "6pLbuAegcVGC1TVrcG3Zyia2t1b+t0uT87sG0pDK4lxs2PBwyPQld1QxkkMc4a7d",
  server: false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
