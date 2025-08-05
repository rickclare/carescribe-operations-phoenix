defmodule OperationsWeb.PageControllerTest do
  use OperationsWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    doc = html_document(conn)

    assert query_text(doc, "h1") =~ "CareScribe Operations"
    assert query_text(doc, "p") =~ "Helping us manage our business"
  end
end
