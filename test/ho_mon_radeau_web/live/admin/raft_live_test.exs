defmodule HoMonRadeauWeb.Admin.RaftLiveTest do
  use HoMonRadeauWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures

  alias HoMonRadeau.Events

  describe "Admin RaftLive.Index" do
    setup %{conn: conn} do
      admin = user_fixture(%{email: "admin@test.com"})

      admin =
        admin
        |> Ecto.Changeset.change(is_admin: true, validated: true)
        |> HoMonRadeau.Repo.update!()

      conn = log_in_user(conn, admin)
      {:ok, edition} = Events.get_or_create_current_edition()

      {:ok, %{crew: _crew}} =
        Events.create_raft_with_crew(admin, %{name: "Raft Alpha"}, edition.id)

      user2 = user_fixture(%{email: "user2@test.com"})

      user2 =
        user2
        |> Ecto.Changeset.change(validated: true)
        |> HoMonRadeau.Repo.update!()

      {:ok, %{crew: _crew2}} =
        Events.create_raft_with_crew(user2, %{name: "Raft Beta"}, edition.id)

      %{conn: conn, admin: admin}
    end

    test "renders raft list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/radeaux")

      assert has_element?(view, "#admin-rafts-table")
      assert render(view) =~ "Raft Alpha"
      assert render(view) =~ "Raft Beta"
    end

    test "validates a raft", %{conn: conn} do
      raft = HoMonRadeau.Repo.get_by!(Events.Raft, name: "Raft Beta")
      {:ok, view, _html} = live(conn, ~p"/admin/radeaux")

      view
      |> element("#raft-#{raft.id} button", "Valider")
      |> render_click()

      assert render(view) =~ "validé"
      assert has_element?(view, "#raft-#{raft.id} .badge-success", "Participant")
    end

    test "invalidates a validated raft", %{conn: conn, admin: admin} do
      raft = HoMonRadeau.Repo.get_by!(Events.Raft, name: "Raft Alpha")
      {:ok, _} = Events.validate_raft(raft, admin)

      {:ok, view, _html} = live(conn, ~p"/admin/radeaux")

      view
      |> element("#raft-#{raft.id} button", "Invalider")
      |> render_click()

      assert render(view) =~ "invalidé"
    end

    test "filters by status", %{conn: conn, admin: admin} do
      raft = HoMonRadeau.Repo.get_by!(Events.Raft, name: "Raft Alpha")
      {:ok, _} = Events.validate_raft(raft, admin)

      {:ok, view, _html} = live(conn, ~p"/admin/radeaux")

      # Filter to show only validated
      view
      |> form("#raft-filters", %{status: "validated", name: ""})
      |> render_change()

      assert render(view) =~ "Raft Alpha"
      refute render(view) =~ "Raft Beta"
    end

    test "filters by name", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/radeaux")

      view
      |> form("#raft-filters", %{status: "all", name: "Alpha"})
      |> render_change()

      assert render(view) =~ "Raft Alpha"
      refute render(view) =~ "Raft Beta"
    end

    test "redirects non-admin users", %{conn: _conn} do
      regular_user = user_fixture(%{email: "regular@test.com"})
      conn = build_conn() |> log_in_user(regular_user)

      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/radeaux")
    end
  end
end
