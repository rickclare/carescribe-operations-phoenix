defmodule OperationsWeb.PageController do
  use OperationsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
