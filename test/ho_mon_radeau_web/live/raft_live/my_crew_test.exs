defmodule HoMonRadeauWeb.RaftLive.MyCrewTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  describe "MyCrew" do
    test "redirects to /radeaux if user has no crew", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/radeaux"}}} =
               live(conn, ~p"/mon-radeau")
    end

    test "shows raft info and crew members", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/mon-radeau")

      assert render(view) =~ "Le Corsaire"
      assert render(view) =~ "membre"
    end

    test "shows management actions for managers", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      # create_raft_with_crew makes the creator a manager
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/mon-radeau")

      # Manager should see the edit button
      assert render(view) =~ "Modifier"
    end

    test "hides management actions for non-managers", %{conn: conn} do
      edition = edition_fixture()
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      _raft = raft_with_crew_fixture(%{user: owner, edition: edition, name: "Le Corsaire"})

      # Add a regular member to the crew
      member_user = user_fixture()
      {:ok, _} = Accounts.validate_user(member_user)
      crew = Events.get_user_crew(owner)
      crew_member_fixture(%{user: member_user, crew: crew, is_manager: false})

      conn = log_in_user(conn, member_user)

      {:ok, view, _html} = live(conn, ~p"/mon-radeau")

      # Non-manager should not see the edit button with phx-click="edit_info"
      refute has_element?(view, "button[phx-click=edit_info]")
    end

    test "non-managers cannot promote themselves to captain via a direct event", %{conn: conn} do
      edition = edition_fixture()
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      raft_with_crew_fixture(%{user: owner, edition: edition, name: "Le Corsaire"})

      member_user = user_fixture()
      {:ok, _} = Accounts.validate_user(member_user)
      crew = Events.get_user_crew(owner)
      crew_member_fixture(%{user: member_user, crew: crew, is_manager: false})

      conn = log_in_user(conn, member_user)
      {:ok, view, _html} = live(conn, ~p"/mon-radeau")

      html = render_click(view, "set_captain", %{"user-id" => to_string(member_user.id)})
      assert html =~ "réservée aux gestionnaires"

      member = Events.get_crew_member(crew.id, member_user.id)
      refute member.is_captain
    end

    test "non-managers cannot remove other members via a direct event", %{conn: conn} do
      edition = edition_fixture()
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      raft_with_crew_fixture(%{user: owner, edition: edition, name: "Le Corsaire"})

      member_user = user_fixture()
      {:ok, _} = Accounts.validate_user(member_user)
      crew = Events.get_user_crew(owner)
      crew_member_fixture(%{user: member_user, crew: crew, is_manager: false})

      conn = log_in_user(conn, member_user)
      {:ok, view, _html} = live(conn, ~p"/mon-radeau")

      html = render_click(view, "remove_member", %{"user-id" => to_string(owner.id)})
      assert html =~ "réservée aux gestionnaires"

      assert Events.get_crew_member(crew.id, owner.id)
    end
  end
end
