defmodule OperationsWeb.OperatorLive.ConfirmationTest do
  use OperationsWeb.ConnCase, async: true

  import Operations.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Operations.Accounts

  setup do
    %{
      unconfirmed_operator: unconfirmed_operator_fixture(),
      confirmed_operator: operator_fixture()
    }
  end

  describe "Confirm operator" do
    test "renders confirmation page for unconfirmed operator", %{
      conn: conn,
      unconfirmed_operator: operator
    } do
      token =
        extract_operator_token(fn url ->
          Accounts.deliver_login_instructions(operator, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/operators/log-in/#{token}")
      assert html =~ "Confirm and stay logged in"
    end

    test "renders login page for confirmed operator", %{conn: conn, confirmed_operator: operator} do
      token =
        extract_operator_token(fn url ->
          Accounts.deliver_login_instructions(operator, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/operators/log-in/#{token}")
      refute html =~ "Confirm my account"
      assert html =~ "Log in"
    end

    test "confirms the given token once", %{conn: conn, unconfirmed_operator: operator} do
      token =
        extract_operator_token(fn url ->
          Accounts.deliver_login_instructions(operator, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/operators/log-in/#{token}")

      form = form(lv, "#confirmation_form", %{"operator" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Operator confirmed successfully"

      assert Accounts.get_operator!(operator.id).confirmed_at
      # we are logged in now
      assert get_session(conn, :operator_token)
      assert redirected_to(conn) == ~p"/"

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        conn
        |> live(~p"/operators/log-in/#{token}")
        |> follow_redirect(conn, ~p"/operators/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "logs confirmed operator in without changing confirmed_at", %{
      conn: conn,
      confirmed_operator: operator
    } do
      token =
        extract_operator_token(fn url ->
          Accounts.deliver_login_instructions(operator, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/operators/log-in/#{token}")

      form = form(lv, "#login_form", %{"operator" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Welcome back!"

      assert Accounts.get_operator!(operator.id).confirmed_at == operator.confirmed_at

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        conn
        |> live(~p"/operators/log-in/#{token}")
        |> follow_redirect(conn, ~p"/operators/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "raises error for invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> live(~p"/operators/log-in/invalid-token")
        |> follow_redirect(conn, ~p"/operators/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end
  end
end
