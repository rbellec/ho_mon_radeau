defmodule HoMonRadeauWeb.Api.CrewControllerTest do
  use HoMonRadeauWeb.ConnCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  describe "GET /api/rafts/:raft_id/crew" do
    test "manager can list their own crew" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft = raft_with_crew_fixture(%{user: manager})

      conn = get(api_conn(manager), ~p"/api/rafts/#{raft.id}/crew")

      assert %{"data" => %{"raft_id" => raft_id, "members" => members}} = json_response(conn, 200)
      assert raft_id == raft.id
      assert length(members) == 1
    end

    test "a manager of another raft cannot list this crew" do
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      raft = raft_with_crew_fixture(%{user: owner})

      other_manager = user_fixture()
      {:ok, _} = Accounts.validate_user(other_manager)
      raft_with_crew_fixture(%{user: other_manager})

      conn = get(api_conn(other_manager), ~p"/api/rafts/#{raft.id}/crew")

      assert json_response(conn, 403)
    end

    test "a regular (non-manager) crew member cannot list the crew" do
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      raft = raft_with_crew_fixture(%{user: owner})

      member = user_fixture()
      {:ok, _} = Accounts.validate_user(member)
      crew = Events.get_user_crew(owner)
      crew_member_fixture(%{user: member, crew: crew, is_manager: false})

      conn = get(api_conn(member), ~p"/api/rafts/#{raft.id}/crew")

      assert json_response(conn, 403)
    end

    test "an admin can list any crew" do
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      raft = raft_with_crew_fixture(%{user: owner})

      admin =
        user_fixture() |> Ecto.Changeset.change(is_admin: true) |> HoMonRadeau.Repo.update!()

      {:ok, admin} = Accounts.validate_user(admin)

      conn = get(api_conn(admin), ~p"/api/rafts/#{raft.id}/crew")

      assert json_response(conn, 200)
    end

    test "unauthenticated requests are rejected" do
      raft = raft_with_crew_fixture()

      conn = get(build_conn(), ~p"/api/rafts/#{raft.id}/crew")

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/rafts/:raft_id/crew/:member_id/set-captain" do
    test "a manager can set a member as captain" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft = raft_with_crew_fixture(%{user: manager})

      other = user_fixture()
      {:ok, _} = Accounts.validate_user(other)
      crew = Events.get_user_crew(manager)
      other_member = crew_member_fixture(%{user: other, crew: crew})

      conn =
        post(
          api_conn(manager),
          ~p"/api/rafts/#{raft.id}/crew/#{other_member.user_id}/set-captain"
        )

      assert %{"data" => %{"is_captain" => true}} = json_response(conn, 200)
      assert Events.get_crew_member(crew.id, other.id).is_captain
    end

    test "returns 404 for a member_id that isn't in the crew" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft = raft_with_crew_fixture(%{user: manager})

      stranger = user_fixture()

      conn =
        post(api_conn(manager), ~p"/api/rafts/#{raft.id}/crew/#{stranger.id}/set-captain")

      assert json_response(conn, 404)
    end
  end

  describe "POST /api/rafts/:raft_id/crew/:member_id/promote and /demote" do
    test "a manager can promote and demote another member" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft = raft_with_crew_fixture(%{user: manager})

      other = user_fixture()
      {:ok, _} = Accounts.validate_user(other)
      crew = Events.get_user_crew(manager)
      other_member = crew_member_fixture(%{user: other, crew: crew})

      conn1 =
        post(api_conn(manager), ~p"/api/rafts/#{raft.id}/crew/#{other_member.user_id}/promote")

      assert %{"data" => %{"is_manager" => true}} = json_response(conn1, 200)

      conn2 =
        post(api_conn(manager), ~p"/api/rafts/#{raft.id}/crew/#{other_member.user_id}/demote")

      assert %{"data" => %{"is_manager" => false}} = json_response(conn2, 200)
    end
  end

  describe "DELETE /api/rafts/:raft_id/crew/:member_id" do
    test "a manager can remove a member" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft = raft_with_crew_fixture(%{user: manager})

      other = user_fixture()
      {:ok, _} = Accounts.validate_user(other)
      crew = Events.get_user_crew(manager)
      crew_member_fixture(%{user: other, crew: crew})

      conn = delete(api_conn(manager), ~p"/api/rafts/#{raft.id}/crew/#{other.id}")

      assert %{"data" => %{"removed" => true}} = json_response(conn, 200)
      refute Events.get_crew_member(crew.id, other.id)
    end

    test "returns 404 when the member doesn't exist in the crew" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft = raft_with_crew_fixture(%{user: manager})

      stranger = user_fixture()

      conn = delete(api_conn(manager), ~p"/api/rafts/#{raft.id}/crew/#{stranger.id}")

      assert json_response(conn, 404)
    end
  end
end
