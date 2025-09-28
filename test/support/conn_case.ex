# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule OperationsWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use OperationsWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use OperationsWeb, :verified_routes

      import OperationsWeb.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn
      # The default endpoint for testing
      @endpoint OperationsWeb.Endpoint

      # Import conveniences for testing with connections

      # Utility functions
      def html_document(conn) do
        conn |> html_response(200) |> LazyHTML.from_document()
      end

      def query_text(nodes, selector) do
        nodes |> LazyHTML.query(selector) |> LazyHTML.text()
      end
    end
  end

  setup tags do
    Operations.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in operators.

      setup :register_and_log_in_operator

  It stores an updated connection and a registered operator in the
  test context.
  """
  def register_and_log_in_operator(%{conn: conn} = context) do
    operator = Operations.AccountsFixtures.operator_fixture()
    scope = Operations.Accounts.Scope.for_operator(operator)

    opts =
      context
      |> Map.take([:token_authenticated_at])
      |> Enum.to_list()

    %{conn: log_in_operator(conn, operator, opts), operator: operator, scope: scope}
  end

  @doc """
  Logs the given `operator` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_operator(conn, operator, opts \\ []) do
    token = Operations.Accounts.generate_operator_session_token(operator)

    maybe_set_token_authenticated_at(token, opts[:token_authenticated_at])

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:operator_token, token)
  end

  defp maybe_set_token_authenticated_at(_token, nil), do: nil

  defp maybe_set_token_authenticated_at(token, authenticated_at) do
    Operations.AccountsFixtures.override_token_authenticated_at(token, authenticated_at)
  end
end
