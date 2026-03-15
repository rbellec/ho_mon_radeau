defmodule HoMonRadeau.Integration.UserLifecycleTest do
  @moduledoc """
  Integration tests verifying complete user lifecycle workflows
  using context functions (pure business logic, no LiveView/HTTP).
  """

  use HoMonRadeau.DataCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  describe "Scenario 1: User registration to raft creation" do
    test "a user registers, gets confirmed and validated, then creates a raft" do
      # Step 1: Register a user
      {:ok, user} =
        Accounts.register_user(%{
          email: unique_user_email(),
          password: valid_user_password()
        })

      assert user.id
      assert is_nil(user.confirmed_at)
      refute user.validated

      # Step 2: Confirm the user (simulate email confirmation)
      confirmed_user =
        user
        |> Ecto.Changeset.change(confirmed_at: DateTime.utc_now(:second))
        |> Repo.update!()

      assert confirmed_user.confirmed_at

      # Step 3: Validate the user via the welcome team
      {:ok, validated_user} = Accounts.validate_user(confirmed_user)
      assert validated_user.validated

      # Step 4: Verify can_participate? requires first_name and last_name
      refute Accounts.can_participate?(validated_user)

      {:ok, complete_user} =
        Accounts.update_user_profile(validated_user, %{
          first_name: "Jean",
          last_name: "Dupont",
          nickname: "Capitaine Jean"
        })

      assert Accounts.can_participate?(complete_user)

      # Step 5: Create a current edition and a raft with crew
      edition = edition_fixture(%{is_current: true})

      {:ok, raft} =
        Events.create_raft_with_crew(complete_user, %{name: "Le Radeau Bleu"}, edition.id)

      assert raft.name == "Le Radeau Bleu"
      assert raft.crew

      # Step 6: Verify the user is a manager of the crew
      crew = Events.get_crew_by_raft(raft.id)
      assert Events.is_crew_manager?(crew, complete_user)
      assert Events.is_manager?(crew.id, complete_user.id)

      # Step 7: Verify the raft appears in current edition rafts
      rafts = Events.list_current_edition_rafts()
      assert Enum.any?(rafts, fn r -> r.id == raft.id end)
    end
  end

  describe "Scenario 2: Join request workflow" do
    test "user B requests to join, manager accepts, other requests are cancelled" do
      edition = edition_fixture(%{is_current: true})

      # Step 1: Create a raft with crew (user A as manager)
      user_a = user_fixture()

      {:ok, raft} =
        Events.create_raft_with_crew(user_a, %{name: "Raft Alpha"}, edition.id)

      crew = Events.get_crew_by_raft(raft.id)

      # Create a second raft for a competing join request
      user_c = user_fixture()

      {:ok, raft_2} =
        Events.create_raft_with_crew(user_c, %{name: "Raft Beta"}, edition.id)

      crew_2 = Events.get_crew_by_raft(raft_2.id)

      # Step 2: Create user B (confirmed + validated)
      user_b =
        user_fixture()
        |> then(fn u ->
          {:ok, u} = Accounts.validate_user(u)
          u
        end)

      # Step 3: User B creates join requests to both crews
      {:ok, request_1} = Events.create_join_request(crew, user_b, "I want to join Raft Alpha!")
      assert request_1.status == "pending"

      {:ok, request_2} = Events.create_join_request(crew_2, user_b, "I want to join Raft Beta!")
      assert request_2.status == "pending"

      # Step 4: Verify has_pending_join_request? is true
      assert Events.has_pending_join_request?(user_b, crew)
      assert Events.has_pending_join_request?(user_b, crew_2)

      # Step 5: User A accepts the request to crew 1
      {:ok, %{request: accepted_request, crew_member: new_member}} =
        Events.accept_join_request(request_1, user_a)

      assert accepted_request.status == "accepted"
      assert new_member.crew_id == crew.id
      assert new_member.user_id == user_b.id

      # Step 6: Verify user B is now a crew member
      member = Events.get_crew_member(crew.id, user_b.id)
      assert member
      assert member.user_id == user_b.id

      # Step 7: Verify user B's other pending requests are cancelled
      updated_request_2 = Repo.get!(Events.CrewJoinRequest, request_2.id)
      assert updated_request_2.status == "cancelled"

      # Step 8: Verify user_has_crew? is true for user B
      assert Events.user_has_crew?(user_b)
    end
  end

  describe "Scenario 3: Join request rejection" do
    test "rejected user can create a new request to another crew" do
      edition = edition_fixture(%{is_current: true})

      # Step 1: Create raft with crew, create user B
      user_a = user_fixture()

      {:ok, raft} =
        Events.create_raft_with_crew(user_a, %{name: "Raft Gamma"}, edition.id)

      crew = Events.get_crew_by_raft(raft.id)

      user_b =
        user_fixture()
        |> then(fn u ->
          {:ok, u} = Accounts.validate_user(u)
          u
        end)

      # Step 2: User B requests to join
      {:ok, request} = Events.create_join_request(crew, user_b, "Please let me in!")
      assert request.status == "pending"

      # Step 3: Manager rejects the request
      {:ok, rejected_request} = Events.reject_join_request(request, user_a)
      assert rejected_request.status == "rejected"

      # Step 4: Verify user B is NOT a crew member
      assert is_nil(Events.get_crew_member(crew.id, user_b.id))
      refute Events.user_has_crew?(user_b)

      # Step 5: Verify user B can create a new request to another crew
      user_d = user_fixture()

      {:ok, raft_2} =
        Events.create_raft_with_crew(user_d, %{name: "Raft Delta"}, edition.id)

      crew_2 = Events.get_crew_by_raft(raft_2.id)

      {:ok, new_request} = Events.create_join_request(crew_2, user_b, "Second chance!")
      assert new_request.status == "pending"
      assert new_request.crew_id == crew_2.id
    end
  end

  describe "Scenario 4: Member departure" do
    test "member leaves crew and departure record is created with correct flags" do
      edition = edition_fixture(%{is_current: true})

      # Step 1: Create raft with crew, add member B
      user_a = user_fixture()

      {:ok, raft} =
        Events.create_raft_with_crew(user_a, %{name: "Raft Epsilon"}, edition.id)

      crew = Events.get_crew_by_raft(raft.id)

      user_b = user_fixture()
      {:ok, _member_b} = Events.add_crew_member(crew.id, user_b.id)

      # Verify user B is in the crew
      assert Events.get_crew_member(crew.id, user_b.id)
      assert Events.user_has_crew?(user_b)

      # Step 2: Assign roles to member B, make them captain
      member_b = Events.get_crew_member(crew.id, user_b.id)
      {:ok, _} = Events.update_member_roles(member_b, ["lead_construction", "safe_contact"])
      {:ok, _} = Events.set_captain(crew.id, user_b.id)

      # Verify captain assignment
      captain = Events.get_captain(crew.id)
      assert captain.user_id == user_b.id

      # Step 3: Member B leaves the crew
      {:ok, %{departure: departure}} = Events.leave_crew(user_b.id, crew.id)

      # Step 4: Verify departure record exists with correct flags
      assert departure.user_id == user_b.id
      assert departure.crew_id == crew.id
      assert departure.was_captain == true
      assert departure.was_manager == false

      # Step 5: Verify member B no longer appears in crew members
      assert is_nil(Events.get_crew_member(crew.id, user_b.id))

      members = Events.list_crew_members(crew.id)
      refute Enum.any?(members, fn m -> m.user_id == user_b.id end)

      # Step 6: Verify user_has_crew? is false for B
      refute Events.user_has_crew?(user_b)
    end
  end
end
