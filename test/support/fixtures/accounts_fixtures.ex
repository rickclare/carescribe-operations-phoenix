defmodule Operations.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Operations.Accounts` context.
  """

  import Ecto.Query

  alias Operations.Accounts
  alias Operations.Accounts.Scope

  def unique_operator_email, do: "operator#{System.unique_integer()}@example.com"
  def valid_operator_password, do: "hello world!"

  def valid_operator_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_operator_email()
    })
  end

  def unconfirmed_operator_fixture(attrs \\ %{}) do
    {:ok, operator} =
      attrs
      |> valid_operator_attributes()
      |> Accounts.register_operator()

    operator
  end

  def operator_fixture(attrs \\ %{}) do
    operator = unconfirmed_operator_fixture(attrs)

    token =
      extract_operator_token(fn url ->
        Accounts.deliver_login_instructions(operator, url)
      end)

    {:ok, {operator, _expired_tokens}} =
      Accounts.login_operator_by_magic_link(token)

    operator
  end

  def operator_scope_fixture do
    operator = operator_fixture()
    operator_scope_fixture(operator)
  end

  def operator_scope_fixture(operator) do
    Scope.for_operator(operator)
  end

  def set_password(operator) do
    {:ok, {operator, _expired_tokens}} =
      Accounts.update_operator_password(operator, %{password: valid_operator_password()})

    operator
  end

  def extract_operator_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Operations.Repo.update_all(
      from(t in Accounts.OperatorToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_operator_magic_link_token(operator) do
    {encoded_token, operator_token} = Accounts.OperatorToken.build_email_token(operator, "login")
    Operations.Repo.insert!(operator_token)
    {encoded_token, operator_token.token}
  end

  def offset_operator_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Operations.Repo.update_all(
      from(ut in Accounts.OperatorToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
