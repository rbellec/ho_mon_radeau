defmodule HoMonRadeauWeb.Admin.UserLiveTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures

  describe "Admin UserLive.Index" do
    setup %{conn: conn} do
      admin = user_fixture(%{email: "admin@test.com"})

      admin =
        admin
        |> Ecto.Changeset.change(is_admin: true, validated: true)
        |> HoMonRadeau.Repo.update!()

      conn = log_in_user(conn, admin)

      regular_user = user_fixture(%{email: "regular@test.com", nickname: "RegularJoe"})

      %{conn: conn, admin: admin, regular_user: regular_user}
    end

    test "lists users", %{conn: conn, regular_user: regular_user} do
      {:ok, view, _html} = live(conn, ~p"/admin/utilisateurs")

      assert render(view) =~ "Gestion des utilisateurs"
      assert render(view) =~ regular_user.email
    end

    test "redirects non-admin users", %{regular_user: regular_user} do
      conn = build_conn() |> log_in_user(regular_user)

      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/utilisateurs")
    end
  end

  describe "Admin UserLive.Show" do
    setup %{conn: conn} do
      admin = user_fixture(%{email: "admin@test.com"})

      admin =
        admin
        |> Ecto.Changeset.change(is_admin: true, validated: true)
        |> HoMonRadeau.Repo.update!()

      conn = log_in_user(conn, admin)

      regular_user = user_fixture(%{email: "regular@test.com", nickname: "RegularJoe"})

      %{conn: conn, admin: admin, regular_user: regular_user}
    end

    test "shows user details", %{conn: conn, regular_user: regular_user} do
      {:ok, view, _html} = live(conn, ~p"/admin/utilisateurs/#{regular_user.id}")

      assert render(view) =~ regular_user.email
      assert render(view) =~ "Informations personnelles"
    end

    test "redirects non-admin users", %{regular_user: regular_user} do
      conn = build_conn() |> log_in_user(regular_user)

      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/utilisateurs/#{regular_user.id}")
    end
  end
end
