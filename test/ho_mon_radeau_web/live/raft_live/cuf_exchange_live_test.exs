defmodule HoMonRadeauWeb.RaftLive.CufExchangeLiveTest do
  use HoMonRadeauWeb.ConnCase

  import Phoenix.LiveViewTest
  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.CUF
  alias HoMonRadeau.Events

  describe "CufExchangeLive" do
    test "redirects to /radeaux if user has no crew", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/radeaux"}}} =
               live(conn, ~p"/mon-radeau/cufexchange")
    end

    test "shows the CUF status for the user's crew", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})

      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/mon-radeau/cufexchange")

      assert html =~ "vot&#39;bon Cuf"
      assert html =~ "0 / 1"
      assert html =~ "il vous manque 1 CUF"
      assert render(view)
    end

    test "a crew member can update the received count", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})
      crew = Events.get_user_crew(user)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/mon-radeau/cufexchange")

      html = view |> form("form[phx-submit=save_received]", %{"count" => "1"}) |> render_submit()

      assert html =~ "1 / 1"
      assert html =~ "vous êtes à jour"
      assert CUF.get_cuf_status(crew.id).received == 1
    end

    test "a crew member can post and cancel a listing", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})
      crew = Events.get_user_crew(user)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/mon-radeau/cufexchange")

      html =
        view
        |> form("#post-listing form", %{"kind" => "request", "quantity" => "2", "note" => "Forum"})
        |> render_submit()

      assert html =~ "Demande"
      assert html =~ "de 2 CUFs"
      assert CUF.get_open_exchange_listing(crew.id).quantity == 2

      html = view |> element("button", "Annuler") |> render_click()
      refute html =~ "de 2 CUFs"
      assert CUF.get_open_exchange_listing(crew.id) == nil
    end

    test "other crews' open listings appear on the board, not the viewer's own", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})
      crew = Events.get_user_crew(user)
      {:ok, _} = CUF.upsert_exchange_listing(crew.id, %{"kind" => "request", "quantity" => "1"})

      other_user = user_fixture()
      {:ok, _} = Accounts.validate_user(other_user)
      raft_with_crew_fixture(%{user: other_user, edition: edition, name: "Le Radeau Ivre"})
      other_crew = Events.get_user_crew(other_user)

      {:ok, _} =
        CUF.upsert_exchange_listing(other_crew.id, %{"kind" => "offer", "quantity" => "1"})

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/mon-radeau/cufexchange")

      assert html =~ "Le Radeau Ivre"
      refute html =~ "Le Corsaire — Offre"
    end

    test "giving CUFs transfers them and shows up in history", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})
      crew = Events.get_user_crew(user)
      {:ok, _} = CUF.update_received_count(crew, 3)

      other_user = user_fixture()
      {:ok, _} = Accounts.validate_user(other_user)
      raft_with_crew_fixture(%{user: other_user, edition: edition, name: "Le Radeau Ivre"})
      other_crew = Events.get_user_crew(other_user)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/mon-radeau/cufexchange")

      html =
        view
        |> form("form[phx-submit=give_cuf]", %{
          "to_crew_id" => to_string(other_crew.id),
          "quantity" => "1"
        })
        |> render_submit()

      assert html =~ "Donné 1 CUF à"
      assert html =~ "Le Radeau Ivre"
      assert CUF.get_cuf_status(crew.id).received == 2
      assert CUF.get_cuf_status(other_crew.id).received == 1
    end

    test "giving more CUFs than available fails gracefully", %{conn: conn} do
      edition = edition_fixture()
      user = user_fixture()
      {:ok, _} = Accounts.validate_user(user)
      raft_with_crew_fixture(%{user: user, edition: edition, name: "Le Corsaire"})
      crew = Events.get_user_crew(user)

      other_user = user_fixture()
      {:ok, _} = Accounts.validate_user(other_user)
      raft_with_crew_fixture(%{user: other_user, edition: edition, name: "Le Radeau Ivre"})
      other_crew = Events.get_user_crew(other_user)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/mon-radeau/cufexchange")

      html =
        view
        |> form("form[phx-submit=give_cuf]", %{
          "to_crew_id" => to_string(other_crew.id),
          "quantity" => "5"
        })
        |> render_submit()

      assert html =~ "Impossible de transférer"
      assert CUF.get_cuf_status(crew.id).received == 0
      assert CUF.get_cuf_status(other_crew.id).received == 0
    end
  end
end
