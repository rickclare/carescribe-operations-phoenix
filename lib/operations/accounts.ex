defmodule Operations.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Operations.Accounts.Operator
  alias Operations.Accounts.OperatorNotifier
  alias Operations.Accounts.OperatorToken
  alias Operations.Repo

  ## Database getters

  @doc """
  Gets a operator by email.

  ## Examples

      iex> get_operator_by_email("foo@example.com")
      %Operator{}

      iex> get_operator_by_email("unknown@example.com")
      nil

  """
  def get_operator_by_email(email) when is_binary(email) do
    Repo.get_by(Operator, email: email)
  end

  @doc """
  Gets a operator by email and password.

  ## Examples

      iex> get_operator_by_email_and_password("foo@example.com", "correct_password")
      %Operator{}

      iex> get_operator_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_operator_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    operator = Repo.get_by(Operator, email: email)
    if Operator.valid_password?(operator, password), do: operator
  end

  @doc """
  Gets a single operator.

  Raises `Ecto.NoResultsError` if the Operator does not exist.

  ## Examples

      iex> get_operator!(123)
      %Operator{}

      iex> get_operator!(456)
      ** (Ecto.NoResultsError)

  """
  def get_operator!(id), do: Repo.get!(Operator, id)

  ## Operator registration

  @doc """
  Registers a operator.

  ## Examples

      iex> register_operator(%{field: value})
      {:ok, %Operator{}}

      iex> register_operator(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_operator(attrs) do
    %Operator{}
    |> Operator.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the operator is in sudo mode.

  The operator is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(operator, minutes \\ -20)

  def sudo_mode?(%Operator{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.add(DateTime.utc_now(), minutes, :minute))
  end

  def sudo_mode?(_operator, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the operator email.

  See `Operations.Accounts.Operator.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_operator_email(operator)
      %Ecto.Changeset{data: %Operator{}}

  """
  def change_operator_email(operator, attrs \\ %{}, opts \\ []) do
    Operator.email_changeset(operator, attrs, opts)
  end

  @doc """
  Updates the operator email using the given token.

  If the token matches, the operator email is updated and the token is deleted.
  """
  def update_operator_email(operator, token) do
    context = "change:#{operator.email}"

    Repo.transact(fn ->
      with {:ok, query} <- OperatorToken.verify_change_email_token_query(token, context),
           %OperatorToken{sent_to: email} <- Repo.one(query),
           {:ok, operator} <- Repo.update(Operator.email_changeset(operator, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(
               from(OperatorToken, where: [operator_id: ^operator.id, context: ^context])
             ) do
        {:ok, operator}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the operator password.

  See `Operations.Accounts.Operator.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_operator_password(operator)
      %Ecto.Changeset{data: %Operator{}}

  """
  def change_operator_password(operator, attrs \\ %{}, opts \\ []) do
    Operator.password_changeset(operator, attrs, opts)
  end

  @doc """
  Updates the operator password.

  Returns a tuple with the updated operator, as well as a list of expired tokens.

  ## Examples

      iex> update_operator_password(operator, %{password: ...})
      {:ok, {%Operator{}, [...]}}

      iex> update_operator_password(operator, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_operator_password(operator, attrs) do
    operator
    |> Operator.password_changeset(attrs)
    |> update_operator_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_operator_session_token(operator) do
    {token, operator_token} = OperatorToken.build_session_token(operator)
    Repo.insert!(operator_token)
    token
  end

  @doc """
  Gets the operator with the given signed token.

  If the token is valid `{operator, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_operator_by_session_token(token) do
    {:ok, query} = OperatorToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the operator with the given magic link token.
  """
  def get_operator_by_magic_link_token(token) do
    with {:ok, query} <- OperatorToken.verify_magic_link_token_query(token),
         {operator, _token} <- Repo.one(query) do
      operator
    else
      _ -> nil
    end
  end

  @doc """
  Logs the operator in by magic link.

  There are three cases to consider:

  1. The operator has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The operator has not confirmed their email and no password is set.
     In this case, the operator gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The operator has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_operator_by_magic_link(token) do
    {:ok, query} = OperatorToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links
      # for unconfirmed users with password
      {%Operator{confirmed_at: nil, hashed_password: hash}, _token} when is_binary(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%Operator{confirmed_at: nil} = operator, _token} ->
        operator
        |> Operator.confirm_changeset()
        |> update_operator_and_delete_all_tokens()

      {operator, token} ->
        Repo.delete!(token)
        {:ok, {operator, []}}

      nil ->
        {:error, :not_found}
    end
  end

  def get_or_create_operator_from_auth!(auth) do
    %{info: %{email: email}} = auth
    operator = get_operator_by_email(email)

    if operator do
      operator
    else
      %Operator{email: email} |> Operator.confirm_changeset() |> Repo.insert!()
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given operator.

  ## Examples

      iex> deliver_operator_update_email_instructions(operator, current_email, &url(~p"/operators/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_operator_update_email_instructions(
        %Operator{} = operator,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, operator_token} =
      OperatorToken.build_email_token(operator, "change:#{current_email}")

    Repo.insert!(operator_token)

    OperatorNotifier.deliver_update_email_instructions(
      operator,
      update_email_url_fun.(encoded_token)
    )
  end

  @doc """
  Delivers the magic link login instructions to the given operator.
  """
  def deliver_login_instructions(%Operator{} = operator, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, operator_token} = OperatorToken.build_email_token(operator, "login")
    Repo.insert!(operator_token)
    OperatorNotifier.deliver_login_instructions(operator, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_operator_session_token(token) do
    Repo.delete_all(from(OperatorToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_operator_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, operator} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(OperatorToken, operator_id: operator.id)

        Repo.delete_all(
          from(t in OperatorToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id))
        )

        {:ok, {operator, tokens_to_expire}}
      end
    end)
  end
end
