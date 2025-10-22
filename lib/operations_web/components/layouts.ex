defmodule OperationsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use OperationsWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main class="p-4 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl">
        <div :if={assigns[:breadcrumb]} class="breadcrumbs text-sm">
          <ul>
            <li>
              <.link class="text-blue-600" href={~p"/"}>Home</.link>
            </li>

            <li :for={item <- assigns[:breadcrumb] || []}>{render_slot(item)}</li>
          </ul>
        </div>

        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="size-3 ml-1 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="size-3 ml-1 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card border-base-300 bg-base-300 relative flex flex-row items-center rounded-full border-2">
      <div class="border-1 border-base-200 bg-base-100 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left] absolute left-0 h-full w-1/3 rounded-full brightness-200" />

      <button
        class="flex w-1/3 cursor-pointer p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex w-1/3 cursor-pointer p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex w-1/3 cursor-pointer p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  def main_nav(assigns) do
    ~H"""
    <nav>
      <ul class="menu menu-horizontal relative z-10 flex w-full items-center justify-center gap-4 px-4 sm:px-6 md:justify-end lg:px-8">
        <%= if @current_scope do %>
          <li>
            {@current_scope.operator.email}
          </li>
          <li>
            <.link href={~p"/operators/settings"}>Settings</.link>
          </li>
          <li>
            <.link href={~p"/operators/log-out"} method="delete">Log out</.link>
          </li>
        <% else %>
          <li>
            <.link href={~p"/operators/register"}>Register</.link>
          </li>
          <li>
            <.link href={~p"/operators/log-in"}>Log in</.link>
          </li>
          <li>
            <.link href={~p"/operators/auth/google"}>
              SSO Log in
            </.link>
          </li>
        <% end %>
      </ul>
    </nav>
    """
  end

  def app_environment(assigns) do
    ~H"""
    <div
      aria-hidden="true"
      class={[
        "z-100 bg-[orange] text-[white] fixed right-0 bottom-0 w-screen",
        "cursor-pointer px-2 py-1 text-center text-xs font-medium md:w-auto md:rounded-tl",
        Application.get_env(:operations, :hide_app_environment) && "hidden"
      ]}
      phx-click={
        JS.hide(
          time: 200,
          transition: {"motion-safe:transition ease-in duration-200", "opacity-100", "opacity-0"}
        )
      }
    >
      {case Application.get_env(:operations, :environment, "Development") do
        :dev -> "Development"
        :prod -> "Production"
        val -> to_string(val) |> String.capitalize()
      end}

      <span class="sm:hidden">[xs]</span>
      <span class="hidden sm:max-md:inline">[sm]</span>
      <span class="hidden md:max-lg:inline">[md]</span>
      <span class="hidden lg:max-xl:inline">[lg]</span>
      <span class="hidden xl:max-2xl:inline">[xl]</span>
      <span class="hidden 2xl:inline">[2xl]</span>
    </div>
    """
  end
end
