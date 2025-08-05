defmodule Operations.Repo do
  use Ecto.Repo,
    otp_app: :operations,
    adapter: Ecto.Adapters.Postgres
end
