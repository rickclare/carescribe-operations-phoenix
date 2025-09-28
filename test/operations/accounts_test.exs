# credo:disable-for-this-file Credo.Check.Refactor.VariableRebinding
defmodule Operations.AccountsTest do
  use Operations.DataCase, async: true

  import Operations.AccountsFixtures

  alias Operations.Accounts
  alias Operations.Accounts.Operator
  alias Operations.Accounts.OperatorToken

  describe "get_operator_by_email/1" do
    test "does not return the operator if the email does not exist" do
      refute Accounts.get_operator_by_email("unknown@example.com")
    end

    test "returns the operator if the email exists" do
      %{id: id} = operator = operator_fixture()
      assert %Operator{id: ^id} = Accounts.get_operator_by_email(operator.email)
    end
  end

  describe "get_operator_by_email_and_password/2" do
    test "does not return the operator if the email does not exist" do
      refute Accounts.get_operator_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the operator if the password is not valid" do
      operator = set_password(operator_fixture())
      refute Accounts.get_operator_by_email_and_password(operator.email, "invalid")
    end

    test "returns the operator if the email and password are valid" do
      %{id: id} = operator = set_password(operator_fixture())

      assert %Operator{id: ^id} =
               Accounts.get_operator_by_email_and_password(
                 operator.email,
                 valid_operator_password()
               )
    end
  end

  describe "get_operator!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_operator!(-1)
      end
    end

    test "returns the operator with the given id" do
      %{id: id} = operator = operator_fixture()
      assert %Operator{id: ^id} = Accounts.get_operator!(operator.id)
    end
  end

  describe "register_operator/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_operator(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_operator(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_operator(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = operator_fixture()
      {:error, changeset} = Accounts.register_operator(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_operator(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers operators without password" do
      email = unique_operator_email()
      {:ok, operator} = Accounts.register_operator(valid_operator_attributes(email: email))
      assert operator.email == email
      assert is_nil(operator.hashed_password)
      assert is_nil(operator.confirmed_at)
      assert is_nil(operator.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%Operator{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%Operator{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%Operator{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %Operator{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%Operator{})
    end
  end

  describe "change_operator_email/3" do
    test "returns a operator changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_operator_email(%Operator{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_operator_update_email_instructions/3" do
    setup do
      %{operator: operator_fixture()}
    end

    test "sends token through notification", %{operator: operator} do
      token =
        extract_operator_token(fn url ->
          Accounts.deliver_operator_update_email_instructions(
            operator,
            "current@example.com",
            url
          )
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert operator_token = Repo.get_by(OperatorToken, token: :crypto.hash(:sha256, token))
      assert operator_token.operator_id == operator.id
      assert operator_token.sent_to == operator.email
      assert operator_token.context == "change:current@example.com"
    end
  end

  describe "update_operator_email/2" do
    setup do
      operator = unconfirmed_operator_fixture()
      email = unique_operator_email()

      token =
        extract_operator_token(fn url ->
          Accounts.deliver_operator_update_email_instructions(
            %{operator | email: email},
            operator.email,
            url
          )
        end)

      %{operator: operator, token: token, email: email}
    end

    test "updates the email with a valid token", %{operator: operator, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_operator_email(operator, token)
      changed_operator = Repo.get!(Operator, operator.id)
      assert changed_operator.email != operator.email
      assert changed_operator.email == email
      refute Repo.get_by(OperatorToken, operator_id: operator.id)
    end

    test "does not update email with invalid token", %{operator: operator} do
      assert Accounts.update_operator_email(operator, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(Operator, operator.id).email == operator.email
      assert Repo.get_by(OperatorToken, operator_id: operator.id)
    end

    test "does not update email if operator email changed", %{operator: operator, token: token} do
      assert Accounts.update_operator_email(%{operator | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(Operator, operator.id).email == operator.email
      assert Repo.get_by(OperatorToken, operator_id: operator.id)
    end

    test "does not update email if token expired", %{operator: operator, token: token} do
      {1, nil} = Repo.update_all(OperatorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_operator_email(operator, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(Operator, operator.id).email == operator.email
      assert Repo.get_by(OperatorToken, operator_id: operator.id)
    end
  end

  describe "change_operator_password/3" do
    test "returns a operator changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_operator_password(%Operator{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_operator_password(
          %Operator{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_operator_password/2" do
    setup do
      %{operator: operator_fixture()}
    end

    test "validates password", %{operator: operator} do
      {:error, changeset} =
        Accounts.update_operator_password(operator, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{operator: operator} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_operator_password(operator, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{operator: operator} do
      {:ok, {operator, expired_tokens}} =
        Accounts.update_operator_password(operator, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(operator.password)
      assert Accounts.get_operator_by_email_and_password(operator.email, "new valid password")
    end

    test "deletes all tokens for the given operator", %{operator: operator} do
      _ = Accounts.generate_operator_session_token(operator)

      {:ok, {_, _}} =
        Accounts.update_operator_password(operator, %{
          password: "new valid password"
        })

      refute Repo.get_by(OperatorToken, operator_id: operator.id)
    end
  end

  describe "generate_operator_session_token/1" do
    setup do
      %{operator: operator_fixture()}
    end

    test "generates a token", %{operator: operator} do
      token = Accounts.generate_operator_session_token(operator)
      assert operator_token = Repo.get_by(OperatorToken, token: token)
      assert operator_token.context == "session"
      assert operator_token.authenticated_at

      # Creating the same token for another operator should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%OperatorToken{
          token: operator_token.token,
          operator_id: operator_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given operator in new token", %{operator: operator} do
      operator = %{operator | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Accounts.generate_operator_session_token(operator)
      assert operator_token = Repo.get_by(OperatorToken, token: token)
      assert operator_token.authenticated_at == operator.authenticated_at
      assert DateTime.after?(operator_token.inserted_at, operator.authenticated_at)
    end
  end

  describe "get_operator_by_session_token/1" do
    setup do
      operator = operator_fixture()
      token = Accounts.generate_operator_session_token(operator)
      %{operator: operator, token: token}
    end

    test "returns operator by token", %{operator: operator, token: token} do
      assert {session_operator, token_inserted_at} = Accounts.get_operator_by_session_token(token)
      assert session_operator.id == operator.id
      assert session_operator.authenticated_at
      assert token_inserted_at
    end

    test "does not return operator for invalid token" do
      refute Accounts.get_operator_by_session_token("oops")
    end

    test "does not return operator for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(OperatorToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_operator_by_session_token(token)
    end
  end

  describe "get_operator_by_magic_link_token/1" do
    setup do
      operator = operator_fixture()
      {encoded_token, _hashed_token} = generate_operator_magic_link_token(operator)
      %{operator: operator, token: encoded_token}
    end

    test "returns operator by token", %{operator: operator, token: token} do
      assert session_operator = Accounts.get_operator_by_magic_link_token(token)
      assert session_operator.id == operator.id
    end

    test "does not return operator for invalid token" do
      refute Accounts.get_operator_by_magic_link_token("oops")
    end

    test "does not return operator for expired token", %{token: token} do
      {1, nil} = Repo.update_all(OperatorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_operator_by_magic_link_token(token)
    end
  end

  describe "login_operator_by_magic_link/1" do
    test "confirms operator and expires tokens" do
      operator = unconfirmed_operator_fixture()
      refute operator.confirmed_at
      {encoded_token, hashed_token} = generate_operator_magic_link_token(operator)

      assert {:ok, {operator, [%{token: ^hashed_token}]}} =
               Accounts.login_operator_by_magic_link(encoded_token)

      assert operator.confirmed_at
    end

    test "returns operator and (deleted) token for confirmed operator" do
      operator = operator_fixture()
      assert operator.confirmed_at
      {encoded_token, _hashed_token} = generate_operator_magic_link_token(operator)
      assert {:ok, {^operator, []}} = Accounts.login_operator_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_operator_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed operator has password set" do
      operator = unconfirmed_operator_fixture()
      {1, nil} = Repo.update_all(Operator, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_operator_magic_link_token(operator)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_operator_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_operator_session_token/1" do
    test "deletes the token" do
      operator = operator_fixture()
      token = Accounts.generate_operator_session_token(operator)
      assert Accounts.delete_operator_session_token(token) == :ok
      refute Accounts.get_operator_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{operator: unconfirmed_operator_fixture()}
    end

    test "sends token through notification", %{operator: operator} do
      token =
        extract_operator_token(fn url ->
          Accounts.deliver_login_instructions(operator, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert operator_token = Repo.get_by(OperatorToken, token: :crypto.hash(:sha256, token))
      assert operator_token.operator_id == operator.id
      assert operator_token.sent_to == operator.email
      assert operator_token.context == "login"
    end
  end

  describe "inspect/2 for the Operator module" do
    test "does not include password" do
      refute inspect(%Operator{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
