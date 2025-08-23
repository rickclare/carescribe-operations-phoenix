defmodule Operations.Repo do
  use Ecto.Repo,
    otp_app: :operations,
    adapter: Ecto.Adapters.Postgres

  alias __MODULE__
  alias Ecto.Query

  @spec count(Ecto.Queryable.t()) :: non_neg_integer
  def count(queryable), do: Repo.aggregate(queryable, :count, :id)

  @spec first(Ecto.Queryable.t()) :: Ecto.Schema.t() | nil
  def first(queryable), do: queryable |> Query.first() |> Repo.one()

  @spec first!(Ecto.Queryable.t()) :: Ecto.Schema.t()
  def first!(queryable), do: queryable |> Query.first() |> Repo.one!()

  @spec last(Ecto.Queryable.t()) :: Ecto.Schema.t() | nil
  def last(queryable), do: queryable |> Query.last() |> Repo.one()

  @spec last!(Ecto.Queryable.t()) :: Ecto.Schema.t()
  def last!(queryable), do: queryable |> Query.last() |> Repo.one!()
end
