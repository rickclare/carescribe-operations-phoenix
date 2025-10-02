# credo:disable-for-this-file Credo.Check.Readability.ImplTrue
defmodule OperationsWeb.OperatorLive.Registration do
  @moduledoc false
  use OperationsWeb, :live_view

  alias Operations.Accounts
  alias Operations.Accounts.Operator

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/operators/log-in"} class="text-brand font-semibold hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{operator: %Operator{}}}} = socket) do
    {:ok, redirect(socket, to: OperationsWeb.OperatorAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_operator_email(%Operator{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"operator" => operator_params}, socket) do
    case Accounts.register_operator(operator_params) do
      {:ok, operator} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            operator,
            &url(~p"/operators/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{operator.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/operators/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"operator" => operator_params}, socket) do
    changeset =
      Accounts.change_operator_email(%Operator{}, operator_params, validate_unique: false)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "operator")
    assign(socket, form: form)
  end
end
