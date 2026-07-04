defmodule HoMonRadeauWeb.Api.UserControllerTest do
  use HoMonRadeauWeb.ConnCase

  import HoMonRadeau.AccountsFixtures

  alias HoMonRadeau.Accounts

  setup do
    admin = user_fixture() |> Ecto.Changeset.change(is_admin: true) |> HoMonRadeau.Repo.update!()
    {:ok, admin} = Accounts.validate_user(admin)
    %{admin: admin}
  end

  describe "GET /api/users" do
    test "an admin can list all confirmed users", %{admin: admin} do
      other = user_fixture(%{email: "other@example.com"})

      conn = get(api_conn(admin), ~p"/api/users")

      assert %{"data" => data} = json_response(conn, 200)
      assert Enum.any?(data, &(&1["id"] == other.id))
    end

    test "a non-admin cannot list users" do
      user = user_fixture()
      {:ok, user} = Accounts.validate_user(user)

      conn = get(api_conn(user), ~p"/api/users")

      assert json_response(conn, 403)
    end
  end

  describe "GET /api/users/search" do
    test "an admin can search users by email", %{admin: admin} do
      user = user_fixture(%{email: "findme@example.com"})

      conn = get(api_conn(admin), ~p"/api/users/search?q=findme")

      assert %{"data" => [found]} = json_response(conn, 200)
      assert found["id"] == user.id
    end
  end

  describe "POST /api/users/:id/validate and /invalidate" do
    test "an admin can validate and invalidate a user", %{admin: admin} do
      user = user_fixture()

      user
      |> Ecto.Changeset.change(validated: false)
      |> HoMonRadeau.Repo.update!()

      conn = post(api_conn(admin), ~p"/api/users/#{user.id}/validate")
      assert %{"data" => %{"validated" => true}} = json_response(conn, 200)

      conn = post(api_conn(admin), ~p"/api/users/#{user.id}/invalidate")
      assert %{"data" => %{"validated" => false}} = json_response(conn, 200)
    end
  end
end
