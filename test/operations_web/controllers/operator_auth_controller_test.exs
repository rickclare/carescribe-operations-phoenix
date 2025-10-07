defmodule OperationsWeb.OperatorAuthControllerTest do
  use OperationsWeb.ConnCase, async: true

  import Operations.AccountsFixtures

  alias Operations.Accounts

  describe "GET /operators/auth/google" do
    test "redirects to Google oAuth2 URL", %{conn: conn} do
      conn = get(conn, ~p"/operators/auth/google")
      url = redirected_to(conn)

      assert url =~ "https://accounts.google.com/o/oauth2/v2/auth?client_id="

      callback_path = ~p"/operators/auth/google/callback"
      redirect_uri = URI.encode_www_form("http://www.example.com" <> callback_path)

      assert url =~ "redirect_uri=#{redirect_uri}"
    end
  end

  describe "GET /operators/auth/google/callback" do
    # skipping: Need to solve CSRF attack issue
    # e.g. https://github.com/ueberauth/ueberauth/discussions/200#discussioncomment-9226531
    @tag :skip
    test "uses authentication info to log in the operator", %{conn: conn} do
      operator = unconfirmed_operator_fixture()
      auth = %Ueberauth.Auth{info: %{email: operator.email}}

      conn =
        conn
        |> bypass_through(OperationsWeb.Router, [:browser])
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/operators/auth/google/callback")
        |> OperationsWeb.OperatorAuthController.callback(%{})

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Successfully authenticated"

      # TODO: Test that the operator is in the session

      assert Accounts.get_operator!(operator.id).confirmed_at
    end

    # skipping: Need to solve CSRF attack issue
    @tag :skip
    test "handles an authentication failure", %{conn: conn} do
      conn = get(conn, ~p"/operators/auth/google/callback")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Failed to authenticate"
    end
  end
end
