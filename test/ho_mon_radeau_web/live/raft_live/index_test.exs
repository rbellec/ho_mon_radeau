defmodule HoMonRadeauWeb.RaftLive.IndexTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts

  describe "Index" do
    test "displays list of rafts when edition exists", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})

      {:ok, view, _html} = live(conn, ~p"/radeaux")

      assert render(view) =~ "Le Corsaire"
      assert render(view) =~ edition.name
    end

    test "shows 'Aucune édition en cours' when no edition", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/radeaux")

      assert render(view) =~ "Aucune édition en cours"
    end

    test "shows 'Aucun radeau' when list is empty", %{conn: conn} do
      _edition = edition_fixture()

      {:ok, view, _html} = live(conn, ~p"/radeaux")

      assert render(view) =~ "Aucun radeau pour le moment"
    end

    test "shows 'Créer un radeau' button for validated user without crew", %{conn: conn} do
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      conn = log_in_user(conn, user)
      _edition = edition_fixture()

      {:ok, view, _html} = live(conn, ~p"/radeaux")

      assert render(view) =~ "Créer un radeau"
    end

    # TODO: TEMPORARY - users auto-validated now, must explicitly unvalidate
    test "hides create button for non-validated user", %{conn: conn} do
      user = user_fixture()
      user |> Ecto.Changeset.change(validated: false) |> HoMonRadeau.Repo.update!()
      conn = log_in_user(conn, user)
      _edition = edition_fixture()

      {:ok, view, _html} = live(conn, ~p"/radeaux")

      refute render(view) =~ "Créer un radeau"
      assert render(view) =~ "Votre compte doit être validé"
    end

    test "accessible without login (public page)", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/radeaux")

      assert html =~ "Les radeaux"
    end
  end
end
