defmodule HoMonRadeauWeb.Api.MeControllerTest do
  use HoMonRadeauWeb.ConnCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts

  describe "GET /api/me" do
    test "returns the current user's dashboard when they have no crew" do
      user = user_fixture()
      {:ok, user} = Accounts.validate_user(user)
      edition_fixture()

      conn = get(api_conn(user), ~p"/api/me")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["profile"]["id"] == user.id
      assert data["crew"] == nil
      assert Enum.any?(data["next_actions"], &(&1["key"] == "join_raft"))
    end

    test "returns crew info when the user belongs to one" do
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft = raft_with_crew_fixture(%{user: user})

      conn = get(api_conn(user), ~p"/api/me")

      assert %{"data" => %{"crew" => crew}} = json_response(conn, 200)
      assert crew["raft_id"] == raft.id
      assert crew["role"] == "manager"
    end

    test "unauthenticated requests are rejected" do
      conn = get(build_conn(), ~p"/api/me")

      assert json_response(conn, 401)
    end

    test "non-validated users are rejected" do
      user = user_fixture()

      user
      |> Ecto.Changeset.change(validated: false)
      |> HoMonRadeau.Repo.update!()

      conn = get(api_conn(user), ~p"/api/me")

      assert json_response(conn, 403)
    end
  end
end
