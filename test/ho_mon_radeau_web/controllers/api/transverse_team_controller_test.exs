defmodule HoMonRadeauWeb.Api.TransverseTeamControllerTest do
  use HoMonRadeauWeb.ConnCase

  import HoMonRadeau.AccountsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  setup do
    admin = user_fixture() |> Ecto.Changeset.change(is_admin: true) |> HoMonRadeau.Repo.update!()
    {:ok, admin} = Accounts.validate_user(admin)
    %{admin: admin}
  end

  describe "GET /api/teams" do
    test "an admin can list transverse teams", %{admin: admin} do
      {:ok, team} =
        Events.create_transverse_team(%{name: "SAFE", transverse_type: "safe_team"})

      conn = get(api_conn(admin), ~p"/api/teams")

      assert %{"data" => data} = json_response(conn, 200)
      assert Enum.any?(data, &(&1["id"] == team.id))
    end
  end

  describe "POST /api/teams" do
    test "an admin can create a transverse team", %{admin: admin} do
      conn =
        post(api_conn(admin), ~p"/api/teams", %{
          "name" => "Medical",
          "transverse_type" => "medical"
        })

      assert %{"data" => %{"name" => "Medical"}} = json_response(conn, 201)
    end
  end

  describe "GET /api/teams/:id, add_member, remove_member" do
    test "an admin can view a team, add and remove a member", %{admin: admin} do
      {:ok, team} =
        Events.create_transverse_team(%{name: "Bidons", transverse_type: "drums_team"})

      user = user_fixture()

      conn = post(api_conn(admin), ~p"/api/teams/#{team.id}/members", %{"user_id" => user.id})
      assert %{"data" => %{"members" => [member]}} = json_response(conn, 200)
      assert member["user_id"] == user.id

      conn = get(api_conn(admin), ~p"/api/teams/#{team.id}")
      assert %{"data" => %{"members" => [_]}} = json_response(conn, 200)

      conn = delete(api_conn(admin), ~p"/api/teams/#{team.id}/members/#{user.id}")
      assert %{"data" => %{"removed" => true}} = json_response(conn, 200)
    end

    test "a non-admin cannot create a team" do
      user = user_fixture()
      {:ok, user} = Accounts.validate_user(user)

      conn = post(api_conn(user), ~p"/api/teams", %{"name" => "Hack"})

      assert json_response(conn, 403)
    end
  end
end
