defmodule HoMonRadeauWeb.Admin.DeparturesLiveTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures

  describe "Admin DeparturesLive" do
    setup %{conn: conn} do
      admin = user_fixture(%{email: "admin@test.com"})

      admin =
        admin
        |> Ecto.Changeset.change(is_admin: true, validated: true)
        |> HoMonRadeau.Repo.update!()

      conn = log_in_user(conn, admin)

      %{conn: conn, admin: admin}
    end

    test "lists departures", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/departs")

      assert render(view) =~ "Suivi des départs"
      assert has_element?(view, "#departures-table")
    end

    test "redirects non-admin users" do
      regular_user = user_fixture(%{email: "regular@test.com"})
      conn = build_conn() |> log_in_user(regular_user)

      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/departs")
    end
  end
end
