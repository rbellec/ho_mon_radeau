defmodule HoMonRadeauWeb.ProfileLiveTest do
  use HoMonRadeauWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "ProfileLive" do
    setup :register_and_log_in_user

    test "renders profile page with user info", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/mon-profil")

      assert has_element?(view, "#profile-header")
      assert has_element?(view, "#profile-form")
      assert has_element?(view, "#email-setting")
      assert has_element?(view, "#password-setting")
      # User is not validated by default
      assert has_element?(view, "#validation-warning")
      assert has_element?(view, "#validation-status")
      # Email displayed in account settings
      assert render(view) =~ user.email
    end

    test "shows validated badge when user is validated", %{conn: conn, user: user} do
      user
      |> Ecto.Changeset.change(validated: true)
      |> HoMonRadeau.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/mon-profil")

      refute has_element?(view, "#validation-warning")
      assert render(view) =~ "Compte validé"
    end

    test "shows name required warning when name is missing", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/mon-profil")

      assert has_element?(view, "#name-required-warning")
    end

    test "hides name warning when name is filled", %{conn: conn, user: user} do
      user
      |> Ecto.Changeset.change(first_name: "Jean", last_name: "Dupont")
      |> HoMonRadeau.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/mon-profil")

      refute has_element?(view, "#name-required-warning")
    end

    test "validates profile form on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/mon-profil")

      result =
        view
        |> form("#profile-form", user: %{nickname: "x"})
        |> render_change()

      # Nickname must be at least 2 characters
      assert result =~ "should be at least 2 character"
    end

    test "updates profile successfully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/mon-profil")

      view
      |> form("#profile-form",
        user: %{
          nickname: "Capitaine42",
          first_name: "Jean",
          last_name: "Dupont",
          phone_number: "06 12 34 56 78"
        }
      )
      |> render_submit()

      assert render(view) =~ "Profil mis à jour avec succès"
      assert render(view) =~ "Capitaine42"
    end

    test "shows crew membership when user is in a crew", %{conn: conn, user: user} do
      # Validate the user first
      user =
        user
        |> Ecto.Changeset.change(validated: true)
        |> HoMonRadeau.Repo.update!()

      # Create an edition and a raft
      {:ok, edition} = HoMonRadeau.Events.get_or_create_current_edition()

      {:ok, %{crew: _crew}} =
        HoMonRadeau.Events.create_raft_with_crew(
          user,
          %{
            name: "Test Raft",
            description: "A test raft"
          },
          edition.id
        )

      {:ok, view, _html} = live(conn, ~p"/mon-profil")

      assert has_element?(view, "#crew-membership")
      assert render(view) =~ "Test Raft"
    end

    test "redirects unauthenticated users to login", %{conn: _conn} do
      conn = build_conn()
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/mon-profil")
    end
  end
end
