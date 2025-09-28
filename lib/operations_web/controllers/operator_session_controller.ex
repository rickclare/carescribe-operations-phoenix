defmodule OperationsWeb.OperatorSessionController do
  use OperationsWeb, :controller

  alias Operations.Accounts
  alias OperationsWeb.OperatorAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "Operator confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # magic link login
  defp create(conn, %{"operator" => %{"token" => token} = operator_params}, info) do
    case Accounts.login_operator_by_magic_link(token) do
      {:ok, {operator, tokens_to_disconnect}} ->
        OperatorAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        |> OperatorAuth.log_in_operator(operator, operator_params)

      _ ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/operators/log-in")
    end
  end

  # email + password login
  defp create(conn, %{"operator" => operator_params}, info) do
    %{"email" => email, "password" => password} = operator_params

    if operator = Accounts.get_operator_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> OperatorAuth.log_in_operator(operator, operator_params)
    else
      # In order to prevent user enumeration attacks,
      # don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/operators/log-in")
    end
  end

  def update_password(conn, %{"operator" => operator_params} = params) do
    operator = conn.assigns.current_scope.operator
    true = Accounts.sudo_mode?(operator)

    {:ok, {_operator, expired_tokens}} =
      Accounts.update_operator_password(operator, operator_params)

    # disconnect all existing LiveViews with old sessions
    OperatorAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:operator_return_to, ~p"/operators/settings")
    |> create(params, "Password updated successfully!")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> OperatorAuth.log_out_operator()
  end
end
