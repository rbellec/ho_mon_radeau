defmodule HoMonRadeauWeb.RaftLive.ShowTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts

  describe "Show" do
    test "displays raft details (name, description)", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)

      raft =
        raft_with_crew_fixture(%{
          user: user,
          edition: edition,
          name: "Le Corsaire",
          description: "A fearless crew sailing the seas"
        })

      {:ok, view, _html} = live(conn, ~p"/radeaux/#{raft.slug}")

      assert render(view) =~ "Le Corsaire"
      assert render(view) =~ "A fearless crew sailing the seas"
    end

    test "redirects with error for non-existent slug", %{conn: conn} do
      _edition = edition_fixture()

      assert {:error, {:redirect, %{to: "/radeaux", flash: %{"error" => "Radeau introuvable."}}}} =
               live(conn, ~p"/radeaux/non-existent-slug")
    end

    test "shows 'Demander à rejoindre' for validated user without crew", %{conn: conn} do
      edition = edition_fixture()
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      raft = raft_with_crew_fixture(%{user: owner, edition: edition, name: "Le Corsaire"})

      visitor = user_fixture()
      {:ok, _} = Accounts.validate_user(visitor)
      conn = log_in_user(conn, visitor)

      {:ok, view, _html} = live(conn, ~p"/radeaux/#{raft.slug}")

      assert render(view) =~ "Demander à rejoindre"
    end

    test "shows member info for crew member", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft = raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/radeaux/#{raft.slug}")

      assert render(view) =~ "Vous êtes membre de cet équipage"
    end

    test "accessible without login", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft = raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})

      {:ok, _view, html} = live(conn, ~p"/radeaux/#{raft.slug}")

      assert html =~ "Le Corsaire"
      assert html =~ "Connectez-vous"
    end
  end
end
