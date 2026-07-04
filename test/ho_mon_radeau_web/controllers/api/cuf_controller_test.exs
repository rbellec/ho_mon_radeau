defmodule HoMonRadeauWeb.Api.CUFControllerTest do
  use HoMonRadeauWeb.ConnCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.CUFFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.CUF

  setup do
    admin = user_fixture() |> Ecto.Changeset.change(is_admin: true) |> HoMonRadeau.Repo.update!()
    {:ok, admin} = Accounts.validate_user(admin)
    %{admin: admin}
  end

  describe "GET /api/cuf" do
    test "an admin can list all CUF declarations", %{admin: admin} do
      declaration_fixture()

      conn = get(api_conn(admin), ~p"/api/cuf")

      assert %{"data" => [_ | _]} = json_response(conn, 200)
    end

    test "a non-admin cannot list CUF declarations" do
      user = user_fixture()
      {:ok, user} = Accounts.validate_user(user)

      conn = get(api_conn(user), ~p"/api/cuf")

      assert json_response(conn, 403)
    end
  end

  describe "GET /api/cuf/settings" do
    test "an admin can read CUF settings", %{admin: admin} do
      cuf_settings_fixture(%{unit_price: Decimal.new("42.00")})

      conn = get(api_conn(admin), ~p"/api/cuf/settings")

      assert %{"data" => %{"unit_price" => "42.00"}} = json_response(conn, 200)
    end
  end

  describe "PUT /api/cuf/settings" do
    test "an admin can update CUF settings", %{admin: admin} do
      cuf_settings_fixture()

      conn =
        put(api_conn(admin), ~p"/api/cuf/settings", %{"unit_price" => "60.00"})

      assert %{"data" => %{"unit_price" => "60.00"}} = json_response(conn, 200)
      assert Decimal.equal?(CUF.get_settings().unit_price, Decimal.new("60.00"))
    end
  end

  describe "POST /api/cuf/:id/validate" do
    test "an admin can validate a CUF declaration", %{admin: admin} do
      declaration = declaration_fixture()

      conn = post(api_conn(admin), ~p"/api/cuf/#{declaration.id}/validate")

      assert %{"data" => %{"status" => "validated"}} = json_response(conn, 200)
    end
  end
end
