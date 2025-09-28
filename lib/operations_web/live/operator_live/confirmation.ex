# credo:disable-for-this-file Credo.Check.Readability.ImplTrue
defmodule OperationsWeb.OperatorLive.Confirmation do
  @moduledoc false
  use OperationsWeb, :live_view

  alias Operations.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>Welcome {@operator.email}</.header>
        </div>

        <.form
          :if={!@operator.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-mounted={JS.focus_first()}
          phx-submit="submit"
          action={~p"/operators/log-in?_action=confirmed"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with="Confirming..."
            class="btn btn-primary w-full"
          >
            Confirm and stay logged in
          </.button>
          <.button phx-disable-with="Confirming..." class="btn btn-primary btn-soft mt-2 w-full">
            Confirm and log in only this time
          </.button>
        </.form>

        <.form
          :if={@operator.confirmed_at}
          for={@form}
          id="login_form"
          phx-submit="submit"
          phx-mounted={JS.focus_first()}
          action={~p"/operators/log-in"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <%= if @current_scope do %>
            <.button phx-disable-with="Logging in..." class="btn btn-primary w-full">
              Log in
            </.button>
          <% else %>
            <.button
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Logging in..."
              class="btn btn-primary w-full"
            >
              Keep me logged in on this device
            </.button>
            <.button phx-disable-with="Logging in..." class="btn btn-primary btn-soft mt-2 w-full">
              Log me in only this time
            </.button>
          <% end %>
        </.form>

        <p :if={!@operator.confirmed_at} class="alert alert-outline mt-8">
          Tip: If you prefer passwords, you can enable them in the operator settings.
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if operator = Accounts.get_operator_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "operator")

      {:ok, assign(socket, operator: operator, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/operators/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"operator" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "operator"), trigger_submit: true)}
  end
end
