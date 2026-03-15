defmodule HoMonRadeauWeb.Admin.DrumsLiveTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures

  describe "Admin DrumsLive.Index" do
    setup %{conn: conn} do
      admin = user_fixture(%{email: "admin@test.com"})

      admin =
        admin
        |> Ecto.Changeset.change(is_admin: true, validated: true)
        |> HoMonRadeau.Repo.update!()

      conn = log_in_user(conn, admin)

      %{conn: conn, admin: admin}
    end

    test "lists drum requests", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/bidons")

      assert render(view) =~ "Gestion des bidons"
      assert has_element?(view, "#drums-stats")
    end

    test "redirects non-admin users" do
      regular_user = user_fixture(%{email: "regular@test.com"})
      conn = build_conn() |> log_in_user(regular_user)

      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/bidons")
    end
  end
end
