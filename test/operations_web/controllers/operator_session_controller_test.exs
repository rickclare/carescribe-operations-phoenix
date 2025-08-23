defmodule OperationsWeb.OperatorSessionControllerTest do
  use OperationsWeb.ConnCase, async: true

  import Operations.AccountsFixtures

  alias Operations.Accounts

  setup do
    %{unconfirmed_operator: unconfirmed_operator_fixture(), operator: operator_fixture()}
  end

  describe "POST /operators/log-in - email and password" do
    test "logs the operator in", %{conn: conn, operator: operator} do
      operator = set_password(operator)

      conn =
        post(conn, ~p"/operators/log-in", %{
          "operator" => %{"email" => operator.email, "password" => valid_operator_password()}
        })

      assert get_session(conn, :operator_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ operator.email
      assert response =~ ~p"/operators/settings"
      assert response =~ ~p"/operators/log-out"
    end

    test "logs the operator in with remember me", %{conn: conn, operator: operator} do
      operator = set_password(operator)

      conn =
        post(conn, ~p"/operators/log-in", %{
          "operator" => %{
            "email" => operator.email,
            "password" => valid_operator_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_operations_web_operator_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the operator in with return to", %{conn: conn, operator: operator} do
      operator = set_password(operator)

      conn =
        conn
        |> init_test_session(operator_return_to: "/foo/bar")
        |> post(~p"/operators/log-in", %{
          "operator" => %{
            "email" => operator.email,
            "password" => valid_operator_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "redirects to login page with invalid credentials", %{conn: conn, operator: operator} do
      conn =
        post(conn, ~p"/operators/log-in?mode=password", %{
          "operator" => %{"email" => operator.email, "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/operators/log-in"
    end
  end

  describe "POST /operators/log-in - magic link" do
    test "logs the operator in", %{conn: conn, operator: operator} do
      {token, _hashed_token} = generate_operator_magic_link_token(operator)

      conn =
        post(conn, ~p"/operators/log-in", %{
          "operator" => %{"token" => token}
        })

      assert get_session(conn, :operator_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ operator.email
      assert response =~ ~p"/operators/settings"
      assert response =~ ~p"/operators/log-out"
    end

    test "confirms unconfirmed operator", %{conn: conn, unconfirmed_operator: operator} do
      {token, _hashed_token} = generate_operator_magic_link_token(operator)
      refute operator.confirmed_at

      conn =
        post(conn, ~p"/operators/log-in", %{
          "operator" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert get_session(conn, :operator_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Operator confirmed successfully."

      assert Accounts.get_operator!(operator.id).confirmed_at

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ operator.email
      assert response =~ ~p"/operators/settings"
      assert response =~ ~p"/operators/log-out"
    end

    test "redirects to login page when magic link is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/operators/log-in", %{
          "operator" => %{"token" => "invalid"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "The link is invalid or it has expired."

      assert redirected_to(conn) == ~p"/operators/log-in"
    end
  end

  describe "DELETE /operators/log-out" do
    test "logs the operator out", %{conn: conn, operator: operator} do
      conn = conn |> log_in_operator(operator) |> delete(~p"/operators/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :operator_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the operator is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/operators/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :operator_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
