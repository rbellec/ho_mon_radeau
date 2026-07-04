defmodule HoMonRadeauWeb.Api.RegistrationFormControllerTest do
  use HoMonRadeauWeb.ConnCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  setup do
    admin = user_fixture() |> Ecto.Changeset.change(is_admin: true) |> HoMonRadeau.Repo.update!()
    {:ok, admin} = Accounts.validate_user(admin)
    %{admin: admin}
  end

  describe "GET /api/registration-forms" do
    test "an admin can list registration forms for the current edition", %{admin: admin} do
      edition = edition_fixture()
      form = registration_form_fixture(%{edition: edition})

      conn = get(api_conn(admin), ~p"/api/registration-forms")

      assert %{"data" => data} = json_response(conn, 200)
      assert Enum.any?(data, &(&1["id"] == form.id))
    end

    test "filters by status", %{admin: admin} do
      edition = edition_fixture()
      registration_form_fixture(%{edition: edition, form_type: "participant"})

      conn = get(api_conn(admin), ~p"/api/registration-forms?status=approved")

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "a non-admin cannot list registration forms" do
      user = user_fixture()
      {:ok, user} = Accounts.validate_user(user)

      conn = get(api_conn(user), ~p"/api/registration-forms")

      assert json_response(conn, 403)
    end
  end

  describe "POST /api/registration-forms/:id/approve" do
    test "an admin can approve a registration form", %{admin: admin} do
      form = registration_form_fixture()

      conn = post(api_conn(admin), ~p"/api/registration-forms/#{form.id}/approve")

      assert %{"data" => %{"status" => "approved"}} = json_response(conn, 200)
    end
  end

  describe "POST /api/registration-forms/:id/reject" do
    test "an admin can reject a registration form with a reason", %{admin: admin} do
      form = registration_form_fixture()

      conn =
        post(api_conn(admin), ~p"/api/registration-forms/#{form.id}/reject", %{
          "reason" => "Illisible"
        })

      assert %{"data" => %{"status" => "rejected", "rejection_reason" => "Illisible"}} =
               json_response(conn, 200)
    end

    test "rejecting without a reason fails validation", %{admin: admin} do
      form = registration_form_fixture()

      conn = post(api_conn(admin), ~p"/api/registration-forms/#{form.id}/reject", %{})

      assert %{"errors" => _} = json_response(conn, 422)
      assert Events.get_registration_form!(form.id).status == "pending"
    end
  end
end
