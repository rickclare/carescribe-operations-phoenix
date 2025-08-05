defmodule OperationsWeb.PageController do
  use OperationsWeb, :controller

  def home(conn, _params) do
    render(conn, :home, page_title: "Home")
  end
end
