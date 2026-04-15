defmodule HoMonRadeauWeb.RaftLive.NewTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts

  describe "New" do
    test "shows creation form for validated user", %{conn: conn} do
      _edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/radeaux/nouveau")

      assert render(view) =~ "Créer un nouveau radeau"
      assert render(view) =~ "Nom du radeau"
    end

    test "redirects to /mon-radeau if user already has a crew", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition})

      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/mon-radeau"}}} =
               live(conn, ~p"/radeaux/nouveau")
    end

    test "creates raft on form submit and redirects", %{conn: conn} do
      _edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/radeaux/nouveau")

      view
      |> form("#raft-form", raft: %{name: "Mon Super Radeau", description: "Great raft"})
      |> render_submit()

      assert_redirect(view, ~p"/mon-radeau")
    end

    test "requires authenticated and validated user", %{conn: conn} do
      # Unauthenticated user is redirected to login
      assert {:error, {:redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/radeaux/nouveau")
    end

    # TODO: TEMPORARY - users auto-validated now, must explicitly unvalidate
    test "redirects non-validated user away", %{conn: conn} do
      user = user_fixture()
      user |> Ecto.Changeset.change(validated: false) |> HoMonRadeau.Repo.update!()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/radeaux/nouveau")
    end
  end
end
