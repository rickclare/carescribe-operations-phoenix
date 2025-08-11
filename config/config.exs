# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure bun (the version is required)
config :bun,
  version: "1.2.20",
  js: [
    args: ~w(
      build js/app.js
        --outdir=../priv/static/assets
        --sourcemap=external
        --external /fonts/*
        --external /images/*
    ),
    cd: Path.expand("../assets", __DIR__),
    env: %{}
  ],
  css: [
    args: ~w(
      --bun tailwindcss
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__),
    env: %{}
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :operations, Operations.Mailer, adapter: Swoosh.Adapters.Local

# Configures the endpoint
config :operations, OperationsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: OperationsWeb.ErrorHTML, json: OperationsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Operations.PubSub,
  live_view: [signing_salt: "syNzHv3E"]

config :operations,
  ecto_repos: [Operations.Repo],
  generators: [timestamp_type: :utc_datetime]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix_live_view, :colocated_js,
  target_directory: Path.expand("../assets/node_modules/phoenix-colocated", __DIR__)

import_config "#{config_env()}.exs"
