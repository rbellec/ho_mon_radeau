defmodule HoMonRadeauWeb.Admin.TransverseTeamLiveTest do
  use HoMonRadeauWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures

  alias HoMonRadeau.Events

  describe "TransverseTeamLive.Index" do
    setup %{conn: conn} do
      admin = user_fixture(%{email: "admin@test.com"})

      admin =
        admin
        |> Ecto.Changeset.change(is_admin: true)
        |> HoMonRadeau.Repo.update!()

      {:ok, team} =
        Events.create_transverse_team(%{
          name: "Accueil",
          transverse_type: "welcome_team",
          description: "Welcome team"
        })

      conn = log_in_user(conn, admin)
      %{conn: conn, admin: admin, team: team}
    end

    test "renders team list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/equipes-transverses")

      assert has_element?(view, "#transverse-teams-table")
      assert render(view) =~ "Accueil"
    end

    test "creates a new team", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/equipes-transverses")

      view |> element("button", "+ Créer une équipe") |> render_click()
      assert has_element?(view, "#transverse-team-form")

      view
      |> form("#transverse-team-form",
        crew: %{name: "SAFE Team", transverse_type: "safe_team"}
      )
      |> render_submit()

      assert render(view) =~ "SAFE Team"
      assert render(view) =~ "créée"
    end

    test "deletes a team", %{conn: conn, team: team} do
      {:ok, view, _html} = live(conn, ~p"/admin/equipes-transverses")

      view
      |> element("#team-#{team.id} button", "Supprimer")
      |> render_click()

      assert render(view) =~ "supprimée"
    end
  end

  describe "TransverseTeamLive.Show" do
    setup %{conn: conn} do
      admin = user_fixture(%{email: "admin@test.com"})

      admin =
        admin
        |> Ecto.Changeset.change(is_admin: true)
        |> HoMonRadeau.Repo.update!()

      {:ok, team} =
        Events.create_transverse_team(%{
          name: "Sécurité",
          transverse_type: "security"
        })

      member = user_fixture(%{email: "member@test.com"})
      {:ok, _} = Events.add_transverse_team_member(team.id, member.id)

      conn = log_in_user(conn, admin)
      %{conn: conn, admin: admin, team: team, member: member}
    end

    test "renders team details with members", %{conn: conn, team: team} do
      {:ok, view, _html} = live(conn, ~p"/admin/equipes-transverses/#{team.id}")

      assert has_element?(view, "#team-members-list")
      assert render(view) =~ "Sécurité"
    end

    test "removes a member", %{conn: conn, team: team, member: member} do
      {:ok, view, _html} = live(conn, ~p"/admin/equipes-transverses/#{team.id}")

      view
      |> element("#member-#{member.id} button", "Retirer")
      |> render_click()

      assert render(view) =~ "retiré"
    end

    test "toggles coordinator role", %{conn: conn, team: team, member: member} do
      {:ok, view, _html} = live(conn, ~p"/admin/equipes-transverses/#{team.id}")

      view
      |> element("#member-#{member.id} button", "Nommer coordinateur")
      |> render_click()

      assert render(view) =~ "mis à jour"
      assert has_element?(view, "#member-#{member.id}", "Coordinateur")
    end
  end
end
