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

  ## ---------------------------------------------------------------
  ## Rafts
  ## ---------------------------------------------------------------

  describe "list_rafts/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns rafts for an edition" do
      edition = edition_fixture(%{is_current: true})
      _raft1 = raft_fixture(%{edition: edition, name: "Alpha"})
      _raft2 = raft_fixture(%{edition: edition, name: "Beta"})

      rafts = Events.list_rafts(edition.id)
      assert length(rafts) == 2
    end

    test "returns empty list for edition without rafts" do
      edition = edition_fixture(%{is_current: false})
      assert Events.list_rafts(edition.id) == []
    end
  end

  describe "list_current_edition_rafts/0" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns rafts of the current edition" do
      edition = edition_fixture(%{is_current: true})
      _raft = raft_fixture(%{edition: edition, name: "Current Raft"})

      rafts = Events.list_current_edition_rafts()
      assert length(rafts) == 1
      assert hd(rafts).name == "Current Raft"
    end

    test "returns empty list when no current edition" do
      assert Events.list_current_edition_rafts() == []
    end
  end

  describe "get_raft!/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns raft with preloads" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition, name: "Loaded Raft"})

      fetched = Events.get_raft!(raft.id)
      assert fetched.name == "Loaded Raft"
      assert Ecto.assoc_loaded?(fetched.crew)
      assert Ecto.assoc_loaded?(fetched.edition)
      assert Ecto.assoc_loaded?(fetched.links)
    end

    test "raises on invalid id" do
      assert_raise Ecto.NoResultsError, fn ->
        Events.get_raft!(0)
      end
    end
  end

  describe "get_raft_by_slug/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns raft by slug and edition" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition, name: "My Cool Raft"})

      found = Events.get_raft_by_slug(raft.slug, edition.id)
      assert found.id == raft.id
    end

    test "returns nil for non-existent slug" do
      edition = edition_fixture(%{is_current: false})
      assert Events.get_raft_by_slug("no-such-slug", edition.id) == nil
    end
  end

  describe "create_raft_with_crew/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "creates raft, crew, and adds user as manager" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()

      assert {:ok, %{crew: crew} = raft} =
               Events.create_raft_with_crew(user, %{name: "New Raft"}, edition.id)

      assert raft.name == "New Raft"
      assert crew != nil

      # The creator should be a manager
      assert Events.is_manager?(crew.id, user.id)
    end

    test "returns :no_current_edition without a current edition" do
      user = user_fixture()
      assert {:error, :no_current_edition} = Events.create_raft_with_crew(user, %{name: "Raft"})
    end

    test "fails with invalid attrs" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Events.create_raft_with_crew(user, %{name: nil}, edition.id)
    end
  end

  describe "update_raft/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "updates raft description" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition, name: "Update Me"})

      assert {:ok, updated} =
               Events.update_raft(raft, %{description: "A brand new description"})

      assert updated.description == "A brand new description"
    end
  end

  describe "validate_raft/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "marks raft as validated" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition, name: "Validate Me"})
      admin = user_fixture()

      assert {:ok, validated} = Events.validate_raft(raft, admin)
      assert validated.validated == true
      assert validated.validated_by_id == admin.id
      assert validated.validated_at != nil
    end
  end

  describe "invalidate_raft/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "revokes validation" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition, name: "Invalidate Me"})
      admin = user_fixture()

      {:ok, validated} = Events.validate_raft(raft, admin)
      assert {:ok, invalidated} = Events.invalidate_raft(validated)
      assert invalidated.validated == false
      assert invalidated.validated_at == nil
      assert invalidated.validated_by_id == nil
    end
  end

  describe "is_crew_manager?/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns true for a manager" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      %{crew: crew} = raft_with_crew_fixture(%{user: user, edition: edition})

      crew = HoMonRadeau.Repo.preload(crew, :crew_members)
      assert Events.is_crew_manager?(crew, user)
    end

    test "returns false for a non-manager" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      other = user_fixture()
      %{crew: crew} = raft_with_crew_fixture(%{user: user, edition: edition})

      crew_member_fixture(%{crew: crew, user: other, is_manager: false})
      crew = HoMonRadeau.Repo.preload(crew, :crew_members)
      refute Events.is_crew_manager?(crew, other)
    end
  end

  ## ---------------------------------------------------------------
  ## Crews
  ## ---------------------------------------------------------------

  describe "get_crew_by_raft/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns crew with members" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      %{crew: crew} = raft_with_crew_fixture(%{user: user, edition: edition})

      fetched = Events.get_crew_by_raft(crew.raft_id)
      assert fetched.id == crew.id
      assert Ecto.assoc_loaded?(fetched.crew_members)
      assert length(fetched.crew_members) >= 1
    end

    test "returns nil without crew" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition})
      assert Events.get_crew_by_raft(raft.id) == nil
    end
  end

  describe "get_user_crew/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns user's crew for current edition" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      %{crew: crew} = raft_with_crew_fixture(%{user: user, edition: edition})

      found = Events.get_user_crew(user)
      assert found.id == crew.id
    end

    test "returns nil if user has no crew" do
      _edition = edition_fixture(%{is_current: true})
      user = user_fixture()

      assert Events.get_user_crew(user) == nil
    end

    test "returns nil if no current edition" do
      user = user_fixture()
      assert Events.get_user_crew(user) == nil
    end
  end

  describe "user_has_crew?/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns true when user has a crew" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      _raft = raft_with_crew_fixture(%{user: user, edition: edition})

      assert Events.user_has_crew?(user)
    end

    test "returns false when user has no crew" do
      _edition = edition_fixture(%{is_current: true})
      user = user_fixture()

      refute Events.user_has_crew?(user)
    end
  end

  ## ---------------------------------------------------------------
  ## Crew Members
  ## ---------------------------------------------------------------

  describe "list_crew_members/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns sorted members" do
      edition = edition_fixture(%{is_current: true})
      manager = user_fixture()
      %{crew: crew} = raft_with_crew_fixture(%{user: manager, edition: edition})

      member = user_fixture()
      crew_member_fixture(%{crew: crew, user: member, is_manager: false})

      members = Events.list_crew_members(crew.id)
      # Manager should come first
      assert length(members) == 2
      assert hd(members).is_manager == true
    end
  end

  describe "add_crew_member/3" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "adds member to crew" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()

      assert {:ok, member} = Events.add_crew_member(crew.id, user.id)
      assert member.crew_id == crew.id
      assert member.user_id == user.id
    end
  end

  describe "remove_crew_member/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "removes member from crew" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()
      crew_member_fixture(%{crew: crew, user: user})

      assert {1, _} = Events.remove_crew_member(crew.id, user.id)
      assert Events.get_crew_member(crew.id, user.id) == nil
    end
  end

  describe "get_crew_member/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns the member" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()
      crew_member_fixture(%{crew: crew, user: user})

      member = Events.get_crew_member(crew.id, user.id)
      assert member != nil
      assert member.user_id == user.id
    end

    test "returns nil for non-member" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()

      assert Events.get_crew_member(crew.id, user.id) == nil
    end
  end

  describe "promote_to_manager/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "promotes a member to manager" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()
      crew_member_fixture(%{crew: crew, user: user, is_manager: false})

      assert {:ok, promoted} = Events.promote_to_manager(crew.id, user.id)
      assert promoted.is_manager == true
    end

    test "returns :not_found for invalid member" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()

      assert {:error, :not_found} = Events.promote_to_manager(crew.id, user.id)
    end
  end

  describe "demote_from_manager/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "demotes a manager" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()
      crew_member_fixture(%{crew: crew, user: user, is_manager: true})

      assert {:ok, demoted} = Events.demote_from_manager(crew.id, user.id)
      assert demoted.is_manager == false
    end

    test "returns :not_found for invalid member" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()

      assert {:error, :not_found} = Events.demote_from_manager(crew.id, user.id)
    end
  end

  describe "is_manager?/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns true for a manager" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()
      crew_member_fixture(%{crew: crew, user: user, is_manager: true})

      assert Events.is_manager?(crew.id, user.id)
    end

    test "returns false for a non-manager" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()
      crew_member_fixture(%{crew: crew, user: user, is_manager: false})

      refute Events.is_manager?(crew.id, user.id)
    end
  end

  ## ---------------------------------------------------------------
  ## Join Requests
  ## ---------------------------------------------------------------

  describe "create_join_request/3" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "creates a join request" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()

      assert {:ok, request} = Events.create_join_request(crew, user, "Please let me in")
      assert request.crew_id == crew.id
      assert request.user_id == user.id
      assert request.message == "Please let me in"
      assert request.status == "pending"
    end

    test "returns :already_in_crew when user has a crew" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      _raft = raft_with_crew_fixture(%{user: user, edition: edition})

      other_crew = crew_fixture(%{edition: edition})

      assert {:error, :already_in_crew} = Events.create_join_request(other_crew, user)
    end
  end

  describe "list_pending_join_requests/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns pending requests for crew" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user1 = user_fixture()
      user2 = user_fixture()

      _req1 = join_request_fixture(%{crew: crew, user: user1})
      _req2 = join_request_fixture(%{crew: crew, user: user2})

      pending = Events.list_pending_join_requests(crew)
      assert length(pending) == 2
      assert Enum.all?(pending, &(&1.status == "pending"))
    end
  end

  describe "accept_join_request/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "adds member and cancels other pending requests" do
      edition = edition_fixture(%{is_current: true})
      crew1 = crew_fixture(%{edition: edition})
      crew2 = crew_fixture(%{edition: edition})
      user = user_fixture()
      user = user |> Ecto.Changeset.change(validated: true) |> HoMonRadeau.Repo.update!()
      responder = user_fixture()

      req1 = join_request_fixture(%{crew: crew1, user: user})
      req2 = join_request_fixture(%{crew: crew2, user: user})

      assert {:ok, %{request: accepted, crew_member: member}} =
               Events.accept_join_request(req1, responder)

      assert accepted.status == "accepted"
      assert member.crew_id == crew1.id
      assert member.user_id == user.id

      # Other pending request should be cancelled
      other = HoMonRadeau.Repo.get!(HoMonRadeau.Events.CrewJoinRequest, req2.id)
      assert other.status == "cancelled"
    end
  end

  describe "reject_join_request/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "rejects with responded_at" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()
      responder = user_fixture()
      request = join_request_fixture(%{crew: crew, user: user})

      assert {:ok, rejected} = Events.reject_join_request(request, responder)
      assert rejected.status == "rejected"
      assert rejected.responded_at != nil
      assert rejected.responded_by_id == responder.id
    end
  end

  describe "has_pending_join_request?/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns true when a pending request exists" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()
      _request = join_request_fixture(%{crew: crew, user: user})

      assert Events.has_pending_join_request?(user, crew)
    end

    test "returns false when no pending request exists" do
      edition = edition_fixture(%{is_current: true})
      crew = crew_fixture(%{edition: edition})
      user = user_fixture()

      refute Events.has_pending_join_request?(user, crew)
    end
  end

  ## ---------------------------------------------------------------
  ## Raft Links
  ## ---------------------------------------------------------------

  describe "list_raft_links/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns links sorted by position" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition})

      _link2 = raft_link_fixture(%{raft: raft, title: "Second", position: 2})
      _link1 = raft_link_fixture(%{raft: raft, title: "First", position: 1})

      links = Events.list_raft_links(raft.id)
      assert length(links) == 2
      assert Enum.at(links, 0).title == "First"
      assert Enum.at(links, 1).title == "Second"
    end
  end

  describe "create_raft_link/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "creates with valid attrs" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition})

      assert {:ok, link} =
               Events.create_raft_link(%{
                 raft_id: raft.id,
                 title: "Docs",
                 url: "https://docs.example.com"
               })

      assert link.title == "Docs"
      assert link.url == "https://docs.example.com"
    end

    test "fails with invalid attrs" do
      assert {:error, %Ecto.Changeset{}} = Events.create_raft_link(%{title: nil, url: nil})
    end
  end

  describe "update_raft_link/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "updates link" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition})
      link = raft_link_fixture(%{raft: raft})

      assert {:ok, updated} = Events.update_raft_link(link, %{title: "Updated Title"})
      assert updated.title == "Updated Title"
    end
  end

  describe "delete_raft_link/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "deletes link" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition})
      link = raft_link_fixture(%{raft: raft})

      assert {:ok, _} = Events.delete_raft_link(link)
      assert Events.list_raft_links(link.raft_id) == []
    end
  end

  describe "list_public_raft_links/1" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns only public links" do
      edition = edition_fixture(%{is_current: true})
      raft = raft_fixture(%{edition: edition})

      _public = raft_link_fixture(%{raft: raft, title: "Public", is_public: true})
      _private = raft_link_fixture(%{raft: raft, title: "Private", is_public: false})

      links = Events.list_public_raft_links(raft.id)
      assert length(links) == 1
      assert hd(links).title == "Public"
    end
  end

  ## ---------------------------------------------------------------
  ## Registration Forms
  ## ---------------------------------------------------------------

  describe "get_current_registration_form/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns most recent form" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()

      old =
        registration_form_fixture(%{user: user, edition: edition})

      # Move the old form's uploaded_at into the past so the ordering is deterministic
      old
      |> Ecto.Changeset.change(uploaded_at: ~U[2025-01-01 00:00:00Z])
      |> HoMonRadeau.Repo.update!()

      new =
        registration_form_fixture(%{user: user, edition: edition})

      found = Events.get_current_registration_form(user.id, edition.id)
      assert found.id == new.id
    end

    test "returns nil if none" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()

      assert Events.get_current_registration_form(user.id, edition.id) == nil
    end
  end

  describe "required_form_type/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns :captain for captain" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      crew = crew_fixture(%{edition: edition})
      crew_member_fixture(%{crew: crew, user: user, is_captain: true})

      assert Events.required_form_type(user, edition.id) == :captain
    end

    test "returns :participant for non-captain member" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      crew = crew_fixture(%{edition: edition})
      crew_member_fixture(%{crew: crew, user: user, is_captain: false})

      assert Events.required_form_type(user, edition.id) == :participant
    end

    test "returns nil for user not in a crew" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()

      assert Events.required_form_type(user, edition.id) == nil
    end
  end

  describe "registration_form_status/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "returns :missing when no form exists" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()

      assert Events.registration_form_status(user, edition.id) == :missing
    end

    test "returns :pending for pending form" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      _form = registration_form_fixture(%{user: user, edition: edition})

      assert Events.registration_form_status(user, edition.id) == :pending
    end

    test "returns :approved for approved form" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      reviewer = user_fixture()
      form = registration_form_fixture(%{user: user, edition: edition})
      {:ok, _} = Events.approve_registration_form(form, reviewer)

      assert Events.registration_form_status(user, edition.id) == :approved
    end

    test "returns :rejected for rejected form" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      reviewer = user_fixture()
      form = registration_form_fixture(%{user: user, edition: edition})
      {:ok, _} = Events.reject_registration_form(form, reviewer, "Bad scan")

      assert Events.registration_form_status(user, edition.id) == :rejected
    end
  end

  describe "approve_registration_form/2" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "approves the form" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      reviewer = user_fixture()
      form = registration_form_fixture(%{user: user, edition: edition})

      assert {:ok, approved} = Events.approve_registration_form(form, reviewer)
      assert approved.status == "approved"
      assert approved.reviewed_by_id == reviewer.id
      assert approved.reviewed_at != nil
    end
  end

  describe "reject_registration_form/3" do
    import HoMonRadeau.AccountsFixtures
    import HoMonRadeau.EventsFixtures, except: [edition_fixture: 0, edition_fixture: 1]

    test "rejects with reason" do
      edition = edition_fixture(%{is_current: true})
      user = user_fixture()
      reviewer = user_fixture()
      form = registration_form_fixture(%{user: user, edition: edition})

      assert {:ok, rejected} =
               Events.reject_registration_form(form, reviewer, "Missing signature")

      assert rejected.status == "rejected"
      assert rejected.rejection_reason == "Missing signature"
      assert rejected.reviewed_by_id == reviewer.id
      assert rejected.reviewed_at != nil
    end
  end
end
