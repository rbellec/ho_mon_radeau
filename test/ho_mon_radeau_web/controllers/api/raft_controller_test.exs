defmodule HoMonRadeauWeb.Api.RaftControllerTest do
  use HoMonRadeauWeb.ConnCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  describe "GET /api/rafts" do
    test "any validated user can list current edition rafts" do
      user = user_fixture()
      {:ok, user} = Accounts.validate_user(user)
      raft = raft_with_crew_fixture()

      conn = get(api_conn(user), ~p"/api/rafts")

      assert %{"data" => data} = json_response(conn, 200)
      assert Enum.any?(data, &(&1["id"] == raft.id))
    end
  end

  describe "GET /api/rafts/:id" do
    test "returns raft details with crew members" do
      owner = user_fixture()
      {:ok, owner} = Accounts.validate_user(owner)
      raft = raft_with_crew_fixture(%{user: owner})

      conn = get(api_conn(owner), ~p"/api/rafts/#{raft.id}")

      assert %{"data" => %{"crew_members" => [member]}} = json_response(conn, 200)
      assert member["user_id"] == owner.id
    end
  end

  describe "POST /api/rafts/:id/validate and /invalidate" do
    test "an admin can validate and invalidate a raft" do
      raft = raft_with_crew_fixture()

      admin =
        user_fixture() |> Ecto.Changeset.change(is_admin: true) |> HoMonRadeau.Repo.update!()

      {:ok, admin} = Accounts.validate_user(admin)

      conn = post(api_conn(admin), ~p"/api/rafts/#{raft.id}/validate")
      assert %{"data" => %{"validated" => true}} = json_response(conn, 200)
      assert Events.get_raft!(raft.id).validated

      conn = post(api_conn(admin), ~p"/api/rafts/#{raft.id}/invalidate")
      assert %{"data" => %{"validated" => false}} = json_response(conn, 200)
      refute Events.get_raft!(raft.id).validated
    end

    test "a non-admin validated user cannot validate a raft" do
      raft = raft_with_crew_fixture()

      user = user_fixture()
      {:ok, user} = Accounts.validate_user(user)

      conn = post(api_conn(user), ~p"/api/rafts/#{raft.id}/validate")

      assert json_response(conn, 403)
      refute Events.get_raft!(raft.id).validated
    end
  end
end
