defmodule OperationsWeb.OperatorLive.SettingsTest do
  use OperationsWeb.ConnCase, async: true

  import Operations.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Operations.Accounts

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_operator(operator_fixture())
        |> live(~p"/operators/settings")

      assert html =~ "Change Email"
      assert html =~ "Save Password"
    end

    test "redirects if operator is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/operators/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/operators/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if operator is not in sudo mode", %{conn: conn} do
      {:ok, conn} =
        conn
        |> log_in_operator(operator_fixture(),
          token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -11, :minute)
        )
        |> live(~p"/operators/settings")
        |> follow_redirect(conn, ~p"/operators/log-in")

      assert conn.resp_body =~ "You must re-authenticate to access this page."
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      operator = operator_fixture()
      %{conn: log_in_operator(conn, operator), operator: operator}
    end

    test "updates the operator email", %{conn: conn, operator: operator} do
      new_email = unique_operator_email()

      {:ok, lv, _html} = live(conn, ~p"/operators/settings")

      result =
        lv
        |> form("#email_form", %{
          "operator" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_operator_by_email(operator.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/operators/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "operator" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, operator: operator} do
      {:ok, lv, _html} = live(conn, ~p"/operators/settings")

      result =
        lv
        |> form("#email_form", %{
          "operator" => %{"email" => operator.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      operator = operator_fixture()
      %{conn: log_in_operator(conn, operator), operator: operator}
    end

    test "updates the operator password", %{conn: conn, operator: operator} do
      new_password = valid_operator_password()

      {:ok, lv, _html} = live(conn, ~p"/operators/settings")

      form =
        form(lv, "#password_form", %{
          "operator" => %{
            "email" => operator.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/operators/settings"

      assert get_session(new_password_conn, :operator_token) != get_session(conn, :operator_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_operator_by_email_and_password(operator.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/operators/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "operator" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Save Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/operators/settings")

      result =
        lv
        |> form("#password_form", %{
          "operator" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Save Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      operator = operator_fixture()
      email = unique_operator_email()

      token =
        extract_operator_token(fn url ->
          Accounts.deliver_operator_update_email_instructions(
            %{operator | email: email},
            operator.email,
            url
          )
        end)

      %{conn: log_in_operator(conn, operator), token: token, email: email, operator: operator}
    end

    test "updates the operator email once", %{
      conn: conn,
      operator: operator,
      token: token,
      email: email
    } do
      {:error, redirect} = live(conn, ~p"/operators/settings/confirm-email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/operators/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_operator_by_email(operator.email)
      assert Accounts.get_operator_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/operators/settings/confirm-email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/operators/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, operator: operator} do
      {:error, redirect} = live(conn, ~p"/operators/settings/confirm-email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/operators/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_operator_by_email(operator.email)
    end

    test "redirects if operator is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/operators/settings/confirm-email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/operators/log-in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
