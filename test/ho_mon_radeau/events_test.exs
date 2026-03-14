defmodule HoMonRadeau.EventsTest do
  use HoMonRadeau.DataCase

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.Edition

  describe "editions" do
    @valid_attrs %{year: 2026, name: "Tutto Blu 2026", is_current: true}
    @update_attrs %{name: "Updated Edition"}
    @invalid_attrs %{year: nil}

    def edition_fixture(attrs \\ %{}) do
      {:ok, edition} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_edition()

      edition
    end

    test "list_editions/0 returns all editions ordered by year desc" do
      _edition_2025 = edition_fixture(%{year: 2025, is_current: false})
      _edition_2026 = edition_fixture(%{year: 2026, is_current: true})

      editions = Events.list_editions()
      assert length(editions) == 2
      assert hd(editions).year == 2026
    end

    test "get_edition!/1 returns the edition with given id" do
      edition = edition_fixture()
      assert Events.get_edition!(edition.id) == edition
    end

    test "get_edition_by_year/1 returns the edition for given year" do
      edition = edition_fixture()
      assert Events.get_edition_by_year(2026) == edition
    end

    test "get_edition_by_year/1 returns nil for non-existent year" do
      assert Events.get_edition_by_year(9999) == nil
    end

    test "get_current_edition/0 returns the current edition" do
      edition_fixture(%{year: 2025, is_current: false})
      current = edition_fixture(%{year: 2026, is_current: true})

      assert Events.get_current_edition().id == current.id
    end

    test "get_current_edition/0 returns nil when no current edition" do
      edition_fixture(%{is_current: false})
      assert Events.get_current_edition() == nil
    end

    test "create_edition/1 with valid data creates an edition" do
      assert {:ok, %Edition{} = edition} = Events.create_edition(@valid_attrs)
      assert edition.year == 2026
      assert edition.name == "Tutto Blu 2026"
      assert edition.is_current == true
    end

    test "create_edition/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_edition(@invalid_attrs)
    end

    test "create_edition/1 enforces unique year constraint" do
      edition_fixture()
      assert {:error, changeset} = Events.create_edition(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).year
    end

    test "create_edition/1 with is_current true unsets other current editions" do
      first = edition_fixture(%{year: 2025, is_current: true})
      _second = edition_fixture(%{year: 2026, is_current: true})

      # Reload first edition
      first = Events.get_edition!(first.id)
      assert first.is_current == false
    end

    test "update_edition/2 with valid data updates the edition" do
      edition = edition_fixture()
      assert {:ok, %Edition{} = edition} = Events.update_edition(edition, @update_attrs)
      assert edition.name == "Updated Edition"
    end

    test "delete_edition/1 deletes the edition" do
      edition = edition_fixture()
      assert {:ok, %Edition{}} = Events.delete_edition(edition)
      assert_raise Ecto.NoResultsError, fn -> Events.get_edition!(edition.id) end
    end

    test "change_edition/1 returns a edition changeset" do
      edition = edition_fixture()
      assert %Ecto.Changeset{} = Events.change_edition(edition)
    end

    test "set_current_edition/1 sets edition as current and unsets others" do
      first = edition_fixture(%{year: 2025, is_current: true})
      second = edition_fixture(%{year: 2026, is_current: false})

      assert {:ok, updated_second} = Events.set_current_edition(second)
      assert updated_second.is_current == true

      # Reload first edition
      first = Events.get_edition!(first.id)
      assert first.is_current == false
    end

    test "get_or_create_current_edition/1 creates edition if not exists" do
      assert {:ok, edition} = Events.get_or_create_current_edition(2030)
      assert edition.year == 2030
      assert edition.is_current == true
    end

    test "get_or_create_current_edition/1 returns existing edition if current" do
      existing = edition_fixture(%{year: 2026, is_current: true})
      assert {:ok, edition} = Events.get_or_create_current_edition(2026)
      assert edition.id == existing.id
    end

    test "validates dates - end_date must be after start_date" do
      attrs = %{year: 2026, start_date: ~D[2026-08-15], end_date: ~D[2026-08-10]}
      assert {:error, changeset} = Events.create_edition(attrs)
      assert "must be after start date" in errors_on(changeset).end_date
    end
  end

  describe "crew member roles" do
    import HoMonRadeau.AccountsFixtures

    setup do
      edition = edition_fixture(%{year: 2026, is_current: true})
      user = user_fixture(%{email: "captain@test.com"})
      user2 = user_fixture(%{email: "member@test.com"})

      user =
        user |> Ecto.Changeset.change(validated: true) |> HoMonRadeau.Repo.update!()

      user2 =
        user2 |> Ecto.Changeset.change(validated: true) |> HoMonRadeau.Repo.update!()

      {:ok, %{crew: crew}} =
        Events.create_raft_with_crew(user, %{name: "Test Raft"}, edition.id)

      # Add second member
      {:ok, member2} =
        %HoMonRadeau.Events.CrewMember{}
        |> HoMonRadeau.Events.CrewMember.changeset(%{crew_id: crew.id, user_id: user2.id})
        |> HoMonRadeau.Repo.insert()

      member1 = Events.get_crew_member(crew.id, user.id)

      %{crew: crew, user: user, user2: user2, member1: member1, member2: member2}
    end

    test "update_member_roles/2 sets roles on a member", %{member1: member} do
      assert {:ok, updated} = Events.update_member_roles(member, ["cooking", "safe_contact"])
      assert "cooking" in updated.roles
      assert "safe_contact" in updated.roles
    end

    test "update_member_roles/2 clears roles when empty list", %{member1: member} do
      {:ok, _} = Events.update_member_roles(member, ["cooking"])
      {:ok, updated} = Events.update_member_roles(member, [])
      assert updated.roles == []
    end

    test "update_member_roles/2 rejects invalid roles", %{member1: member} do
      assert {:error, changeset} = Events.update_member_roles(member, ["invalid_role"])
      assert errors_on(changeset)[:roles]
    end

    test "set_captain/2 sets a member as captain", %{crew: crew, user2: user2} do
      {:ok, captain} = Events.set_captain(crew.id, user2.id)
      assert captain.is_captain == true
    end

    test "set_captain/2 replaces existing captain", %{crew: crew, user: user, user2: user2} do
      {:ok, _} = Events.set_captain(crew.id, user.id)
      {:ok, new_captain} = Events.set_captain(crew.id, user2.id)
      assert new_captain.is_captain == true

      # Old captain should no longer be captain
      old = Events.get_crew_member(crew.id, user.id)
      assert old.is_captain == false
    end

    test "get_captain/1 returns the captain", %{crew: crew, user: user} do
      {:ok, _} = Events.set_captain(crew.id, user.id)
      captain = Events.get_captain(crew.id)
      assert captain.user_id == user.id
    end

    test "get_captain/1 returns nil when no captain", %{crew: crew} do
      assert Events.get_captain(crew.id) == nil
    end

    test "remove_captain/1 removes captain role", %{crew: crew, user: user} do
      {:ok, _} = Events.set_captain(crew.id, user.id)
      Events.remove_captain(crew.id)
      assert Events.get_captain(crew.id) == nil
    end

    test "get_roles_summary/1 returns role assignments", %{crew: crew, member1: m1, member2: m2} do
      {:ok, _} = Events.update_member_roles(m1, ["cooking"])
      {:ok, _} = Events.update_member_roles(m2, ["cooking", "safe_contact"])

      summary = Events.get_roles_summary(crew.id)
      assert length(summary["cooking"]) == 2
      assert length(summary["safe_contact"]) == 1
      assert summary["lead_construction"] == []
    end
  end

  describe "crew departures" do
    import HoMonRadeau.AccountsFixtures

    setup do
      edition = edition_fixture(%{year: 2030, is_current: true})
      user = user_fixture(%{email: "leaving@test.com"})
      user = user |> Ecto.Changeset.change(validated: true) |> HoMonRadeau.Repo.update!()

      {:ok, %{crew: crew}} =
        Events.create_raft_with_crew(user, %{name: "Departure Raft"}, edition.id)

      %{crew: crew, user: user}
    end

    test "leave_crew/2 removes member and records departure", %{crew: crew, user: user} do
      assert {:ok, %{member: _, departure: departure}} = Events.leave_crew(user.id, crew.id)
      assert departure.user_id == user.id
      assert departure.crew_id == crew.id
      assert departure.was_manager == true
      assert is_nil(departure.removed_by_id)
    end

    test "leave_crew/3 with removed_by records who removed", %{crew: crew, user: user} do
      admin = user_fixture(%{email: "admin_remover@test.com"})

      assert {:ok, %{departure: departure}} =
               Events.leave_crew(user.id, crew.id, removed_by_id: admin.id)

      assert departure.removed_by_id == admin.id
    end

    test "leave_crew/2 returns error for non-member", %{crew: crew} do
      non_member = user_fixture(%{email: "nonmember@test.com"})
      assert {:error, :not_found} = Events.leave_crew(non_member.id, crew.id)
    end

    test "list_crew_departures/0 returns departures", %{crew: crew, user: user} do
      {:ok, _} = Events.leave_crew(user.id, crew.id)
      departures = Events.list_crew_departures()
      assert length(departures) >= 1
      assert hd(departures).user_id == user.id
    end
  end

  describe "transverse teams" do
    import HoMonRadeau.AccountsFixtures

    test "create_transverse_team/1 creates a team" do
      assert {:ok, team} =
               Events.create_transverse_team(%{
                 name: "SAFE",
                 transverse_type: "safe_team",
                 description: "Safety team"
               })

      assert team.name == "SAFE"
      assert team.is_transverse == true
      assert team.transverse_type == "safe_team"
    end

    test "create_transverse_team/1 rejects invalid type" do
      assert {:error, changeset} =
               Events.create_transverse_team(%{name: "Bad", transverse_type: "invalid"})

      assert errors_on(changeset)[:transverse_type]
    end

    test "list_transverse_teams/0 returns all teams" do
      {:ok, _} =
        Events.create_transverse_team(%{name: "Team A", transverse_type: "welcome_team"})

      {:ok, _} = Events.create_transverse_team(%{name: "Team B", transverse_type: "safe_team"})

      teams = Events.list_transverse_teams()
      assert length(teams) == 2
    end

    test "add and remove transverse team members" do
      {:ok, team} =
        Events.create_transverse_team(%{name: "Bidons", transverse_type: "drums_team"})

      user = user_fixture()

      assert {:ok, _member} = Events.add_transverse_team_member(team.id, user.id)

      loaded = Events.get_transverse_team!(team.id)
      assert length(loaded.crew_members) == 1

      assert {:ok, _} = Events.remove_transverse_team_member(team.id, user.id)

      loaded = Events.get_transverse_team!(team.id)
      assert length(loaded.crew_members) == 0
    end

    test "get_user_transverse_teams/1 returns user's teams" do
      user = user_fixture()

      {:ok, team1} =
        Events.create_transverse_team(%{name: "Team 1", transverse_type: "security"})

      {:ok, team2} =
        Events.create_transverse_team(%{name: "Team 2", transverse_type: "medical"})

      Events.add_transverse_team_member(team1.id, user.id)
      Events.add_transverse_team_member(team2.id, user.id)

      teams = Events.get_user_transverse_teams(user)
      assert length(teams) == 2
    end

    test "member_of_team_type?/2 checks team type membership" do
      user = user_fixture()

      {:ok, team} =
        Events.create_transverse_team(%{name: "Accueil", transverse_type: "welcome_team"})

      refute Events.member_of_team_type?(user, "welcome_team")

      Events.add_transverse_team_member(team.id, user.id)
      assert Events.member_of_team_type?(user, "welcome_team")
    end
  end
end
