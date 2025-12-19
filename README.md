# Operations

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Running Playwright tests

```sh
mix playwright.setup

# Headless browser testing (see https://github.com/oven-sh/bun/issues/8222#issuecomment-3665364677)
PW_DISABLE_TS_ESM=1 _build/bun --cwd=playwright playwright test

# NOTE: The UI mode of Playwright does not currently work well without Node
#       (without Node, the UI does not show a list of available tests files)
mise exec node@latest -- _build/bun --cwd=playwright playwright test --ui
```

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
