defmodule Operations.MixProject do
  use Mix.Project

  def project do
    [
      app: :operations,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      gettext: [
        on_obsolete: :mark_as_obsolete,
        sort_by_msgid: :case_sensitive,
        # write_reference_line_numbers: false,
        write_reference_comments: false
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Operations.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        "playwrigh
t       .setup": :e2e,
        "playwright.prepare": :e2e
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :e2e]},
      {:phoenix_live_view, "~> 1.1"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:bun, "~> 1.4", runtime: Mix.env() in [:dev, :e2e]},
      {
        :heroicons,
        github: "tailwindlabs/heroicons",
        tag: "v2.2.0",
        sparse: "optimized",
        app: false,
        compile: false,
        depth: 1
      },
      {
        :phosphor_icons,
        tag: "main",
        github: "phosphor-icons/core",
        sparse: "assets",
        app: false,
        compile: false,
        depth: 1
      },
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.8"},
      {:ueberauth_google, "~> 0.10"},
      #
      {:credo, "~> 1.7.12", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.9", only: [:dev, :test], runtime: false},
      {:tailwind_formatter, "~> 0.4.2", only: [:dev, :test], runtime: false},
      {:tidewave, "~> 0.5", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.load", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "playwright.setup": [
        "ecto.create --quiet",
        "ecto.load --quiet --skip-if-loaded",
        "assets.setup",
        "playwright.prepare"
      ],
      "playwright.prepare": ["ecto.migrate --quiet", "assets.build"],
      "assets.setup": [
        "bun.install --if-missing",
        "cmd _build/bun --silent install"
      ],
      "assets.build": [
        "compile",
        "bun css",
        "bun js"
      ],
      "assets.setup_deploy": [
        "bun.install --if-missing",
        "cmd _build/bun install --production --frozen-lockfile"
      ],
      "assets.deploy": [
        "bun css --minify",
        "bun js --minify",
        "phx.digest"
      ],
      precommit: [
        "compile --warning-as-errors",
        "deps.unlock --unused",
        "format",
        "test"
      ],
      "dev.checks": [
        "format --dry-run --check-formatted",
        "gettext.extract --check-up-to-date",
        "compile --warnings-as-errors --all-warnings",
        "credo --all --format=oneline --min-priority=low",
        # "dialyzer --quiet",
        "cmd _build/bun --silent install",
        ~s{cmd _build/bun --bun prettier --log-level=warn --check --ignore-unknown "**"},
        "cmd _build/bun --bun stylelint assets/css/**/*.css",
        "cmd _build/bun --bun eslint",
        "cmd _build/bun --bun tsc --noEmit --project tsconfig.json"
      ]
    ]
  end
end
