defmodule HoMonRadeauWeb.RegistrationFormLiveTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Repo

  # Helper to create a valid edition (year must be < 3000)
  defp valid_edition(attrs) do
    edition_fixture(Map.put_new(attrs, :year, 2026))
  end

  # Helper to update a registration form's status after creation
  # (the changeset only casts a limited set of fields)
  defp set_form_status(form, status, extra_attrs \\ %{}) do
    form
    |> Ecto.Changeset.change(Map.merge(%{status: status}, extra_attrs))
    |> Repo.update!()
  end

  describe "RegistrationFormLive.Index" do
    setup :register_and_log_in_user

    setup %{user: user} do
      # Validate user so they can access the registration form page
      user =
        user
        |> Ecto.Changeset.change(validated: true)
        |> Repo.update!()

      %{user: user}
    end

    test "redirects if no current edition exists", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/", flash: %{"error" => "Aucune édition en cours"}}}} =
               live(conn, ~p"/fiche-inscription")
    end

    test "shows join a crew message if user has no crew", %{conn: conn} do
      _edition = valid_edition(%{is_current: true})

      {:ok, view, _html} = live(conn, ~p"/fiche-inscription")

      assert render(view) =~ "rejoindre un équipage"
    end

    test "shows form instructions when user has a crew with form URLs", %{
      conn: conn,
      user: user
    } do
      edition =
        valid_edition(%{
          is_current: true,
          participant_form_url: "https://example.com/participant.pdf",
          captain_form_url: "https://example.com/captain.pdf"
        })

      _raft_result =
        raft_with_crew_fixture(%{user: user, edition: edition, name: "Test Crew Raft"})

      {:ok, view, _html} = live(conn, ~p"/fiche-inscription")

      html = render(view)
      assert html =~ "Instructions"
      assert html =~ "Envoyer votre fiche"
    end

    test "shows captain form link when user is captain", %{conn: conn, user: user} do
      edition =
        valid_edition(%{
          is_current: true,
          captain_form_url: "https://example.com/captain.pdf"
        })

      # Creating a raft makes the user a manager; we also set them as captain
      %{crew: crew} =
        raft_with_crew_fixture(%{user: user, edition: edition, name: "Captain Raft"})

      crew_member =
        Repo.get_by!(HoMonRadeau.Events.CrewMember, crew_id: crew.id, user_id: user.id)

      crew_member
      |> Ecto.Changeset.change(is_captain: true)
      |> Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/fiche-inscription")

      html = render(view)
      assert html =~ "Fiche capitaine"
      assert html =~ "https://example.com/captain.pdf"
    end

    test "shows missing status when no form has been submitted", %{conn: conn, user: user} do
      edition = valid_edition(%{is_current: true})
      _raft_result = raft_with_crew_fixture(%{user: user, edition: edition})

      {:ok, view, _html} = live(conn, ~p"/fiche-inscription")

      assert render(view) =~ "Fiche non envoyée"
    end

    test "shows pending status when form is pending", %{conn: conn, user: user} do
      edition = valid_edition(%{is_current: true})
      _raft_result = raft_with_crew_fixture(%{user: user, edition: edition})

      _form = registration_form_fixture(%{user: user, edition: edition})

      {:ok, view, _html} = live(conn, ~p"/fiche-inscription")

      assert render(view) =~ "Fiche en attente de validation"
    end

    test "shows approved status when form is approved", %{conn: conn, user: user} do
      edition = valid_edition(%{is_current: true})
      _raft_result = raft_with_crew_fixture(%{user: user, edition: edition})

      form = registration_form_fixture(%{user: user, edition: edition})
      set_form_status(form, "approved")

      {:ok, view, _html} = live(conn, ~p"/fiche-inscription")

      assert render(view) =~ "Fiche validée"
    end

    test "shows rejected status with reason when form is rejected", %{conn: conn, user: user} do
      edition = valid_edition(%{is_current: true})
      _raft_result = raft_with_crew_fixture(%{user: user, edition: edition})

      form = registration_form_fixture(%{user: user, edition: edition})
      set_form_status(form, "rejected", %{rejection_reason: "Document illisible"})

      {:ok, view, _html} = live(conn, ~p"/fiche-inscription")

      html = render(view)
      assert html =~ "Fiche rejetée"
      assert html =~ "Document illisible"
    end
  end

  describe "RegistrationFormLive.Index - authentication" do
    test "redirects unauthenticated users to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/fiche-inscription")
    end

    test "redirects non-validated users", %{conn: conn} do
      conn = register_and_log_in_user(%{conn: conn}).conn

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/fiche-inscription")
    end
  end
end
