defmodule HoMonRadeauWeb.Api.JoinRequestControllerTest do
  use HoMonRadeauWeb.ConnCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  describe "GET /api/rafts/:raft_id/join-requests" do
    test "a manager can list pending join requests for their crew" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft = raft_with_crew_fixture(%{user: manager})
      crew = Events.get_user_crew(manager)

      applicant = user_fixture()
      join_request_fixture(%{user: applicant, crew: crew})

      conn = get(api_conn(manager), ~p"/api/rafts/#{raft.id}/join-requests")

      assert %{"data" => [%{"user_id" => user_id}]} = json_response(conn, 200)
      assert user_id == applicant.id
    end

    test "a manager of another raft cannot list this crew's join requests" do
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      raft = raft_with_crew_fixture(%{user: owner})

      other_manager = user_fixture()
      {:ok, _} = Accounts.validate_user(other_manager)
      raft_with_crew_fixture(%{user: other_manager})

      conn = get(api_conn(other_manager), ~p"/api/rafts/#{raft.id}/join-requests")

      assert json_response(conn, 403)
    end
  end

  describe "POST /api/join-requests/:id/accept" do
    test "a manager can accept a join request for their crew" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft_with_crew_fixture(%{user: manager})
      crew = Events.get_user_crew(manager)

      applicant = user_fixture()
      {:ok, _} = Accounts.validate_user(applicant)
      request = join_request_fixture(%{user: applicant, crew: crew})

      conn = post(api_conn(manager), ~p"/api/join-requests/#{request.id}/accept")

      assert %{"data" => %{"accepted" => true}} = json_response(conn, 200)
      assert Events.get_crew_member(crew.id, applicant.id)
    end

    test "a manager of a different crew cannot accept this join request" do
      owner = user_fixture()
      {:ok, _} = Accounts.validate_user(owner)
      raft_with_crew_fixture(%{user: owner})
      crew = Events.get_user_crew(owner)

      applicant = user_fixture()
      {:ok, _} = Accounts.validate_user(applicant)
      request = join_request_fixture(%{user: applicant, crew: crew})

      other_manager = user_fixture()
      {:ok, _} = Accounts.validate_user(other_manager)
      raft_with_crew_fixture(%{user: other_manager})

      conn = post(api_conn(other_manager), ~p"/api/join-requests/#{request.id}/accept")

      assert json_response(conn, 403)
      refute Events.get_crew_member(crew.id, applicant.id)
    end
  end

  describe "POST /api/join-requests/:id/reject" do
    test "a manager can reject a join request for their crew" do
      manager = user_fixture()
      {:ok, _} = Accounts.validate_user(manager)
      raft_with_crew_fixture(%{user: manager})
      crew = Events.get_user_crew(manager)

      applicant = user_fixture()
      request = join_request_fixture(%{user: applicant, crew: crew})

      conn = post(api_conn(manager), ~p"/api/join-requests/#{request.id}/reject")

      assert %{"data" => %{"rejected" => true}} = json_response(conn, 200)
    end
  end
end
