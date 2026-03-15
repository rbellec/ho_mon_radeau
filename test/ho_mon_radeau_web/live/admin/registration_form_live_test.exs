defmodule HoMonRadeauWeb.Admin.RegistrationFormLiveTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures

  alias HoMonRadeau.Events

  describe "Admin RegistrationFormLive.Index" do
    setup %{conn: conn} do
      admin = user_fixture(%{email: "admin@test.com"})

      admin =
        admin
        |> Ecto.Changeset.change(is_admin: true, validated: true)
        |> HoMonRadeau.Repo.update!()

      conn = log_in_user(conn, admin)

      %{conn: conn, admin: admin}
    end

    test "lists forms when edition exists", %{conn: conn} do
      {:ok, _edition} = Events.get_or_create_current_edition()

      {:ok, view, _html} = live(conn, ~p"/admin/fiches")

      assert render(view) =~ "Fiches d&#39;inscription"
    end

    test "redirects non-admin users" do
      regular_user = user_fixture(%{email: "regular@test.com"})
      conn = build_conn() |> log_in_user(regular_user)

      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/fiches")
    end

    test "redirects when no edition exists", %{conn: conn} do
      # No edition created, so mount should redirect to home
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/fiches")
    end
  end
end
