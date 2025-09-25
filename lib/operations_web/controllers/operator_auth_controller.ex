defmodule OperationsWeb.OperatorAuthController do
  use OperationsWeb, :controller

  alias Operations.Accounts
  alias OperationsWeb.OperatorAuth

  plug Ueberauth
  require Logger

  def callback(%{assigns: %{ueberauth_failure: %Ueberauth.Failure{} = failure}} = conn, _params) do
    Logger.error(failure)

    conn
    |> put_flash(:error, "Failed to authenticate")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_auth: %Ueberauth.Auth{} = auth}} = conn, _params) do
    operator = Accounts.get_or_create_operator_from_auth!(auth)

    conn
    |> put_flash(:info, "Successfully authenticated")
    |> OperatorAuth.log_in_operator(operator)
  end
end
