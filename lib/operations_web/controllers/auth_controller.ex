defmodule OperationsWeb.AuthController do
  use OperationsWeb, :controller

  require Logger

  plug Ueberauth

  def callback(%{assigns: %{ueberauth_failure: %Ueberauth.Failure{}}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_auth: %Ueberauth.Auth{} = auth}} = conn, _params) do
    ## You will have to implement this function that inserts into the database
    # operator = OperationsWeb.Accounts.create_operator_from_ueberauth!(auth)

    ## If you are using mix phx.gen.auth, you can use it to login
    # Operations.OperatorAuth.log_in_operator(conn, operator)

    ## If you are not using mix phx.gen.auth, store the operator-user in the session
    # conn
    # |> renew_session()
    # |> put_session(:operator_id, operator.id)
    # |> redirect(to: ~p"/")

    redirect(conn, to: ~p"/")
  end
end
