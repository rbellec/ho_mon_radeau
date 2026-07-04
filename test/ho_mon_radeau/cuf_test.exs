defmodule HoMonRadeau.CUFTest do
  use HoMonRadeau.DataCase

  alias HoMonRadeau.CUF
  alias HoMonRadeau.Events

  import HoMonRadeau.AccountsFixtures

  setup do
    user1 = user_fixture(%{email: "captain@test.com"})
    user2 = user_fixture(%{email: "member@test.com"})

    user1 =
      user1
      |> Ecto.Changeset.change(validated: true)
      |> Repo.update!()

    user2 =
      user2
      |> Ecto.Changeset.change(validated: true)
      |> Repo.update!()

    {:ok, edition} = Events.get_or_create_current_edition()

    {:ok, %{crew: crew}} =
      Events.create_raft_with_crew(user1, %{name: "CUF Test Raft"}, edition.id)

    {:ok, _} =
      %Events.CrewMember{}
      |> Events.CrewMember.changeset(%{crew_id: crew.id, user_id: user2.id})
      |> Repo.insert()

    %{crew: crew, user1: user1, user2: user2}
  end

  describe "settings" do
    test "get_settings/0 returns defaults" do
      settings = CUF.get_settings()
      assert Decimal.equal?(settings.unit_price, Decimal.new(50))
    end

    test "update_settings/1 creates or updates settings" do
      assert {:ok, settings} = CUF.update_settings(%{unit_price: "75", total_limit: 500})
      assert Decimal.equal?(settings.unit_price, Decimal.new(75))
      assert settings.total_limit == 500
    end
  end

  describe "declarations" do
    test "create_declaration/2 creates a declaration", %{crew: crew, user1: u1, user2: u2} do
      assert {:ok, decl} = CUF.create_declaration(crew.id, [u1.id, u2.id])
      assert decl.participant_count == 2
      assert decl.status == "pending"
      assert Decimal.equal?(decl.unit_price, Decimal.new(50))
      assert Decimal.equal?(decl.total_amount, Decimal.new(100))
      assert u1.id in decl.participant_user_ids
      assert u2.id in decl.participant_user_ids
    end

    test "validate_declaration/2 validates and updates member status", %{
      crew: crew,
      user1: u1,
      user2: u2
    } do
      {:ok, decl} = CUF.create_declaration(crew.id, [u1.id, u2.id])
      admin = user_fixture(%{email: "admin@test.com"})

      assert {:ok, %{declaration: validated}} = CUF.validate_declaration(decl, admin.id)
      assert validated.status == "validated"
      assert validated.validated_at != nil

      # Members should be marked as confirmed
      m1 = Events.get_crew_member(crew.id, u1.id)
      assert m1.participation_status == "confirmed"
    end

    test "get_crew_cuf_summary/1 returns correct data", %{crew: crew, user1: u1} do
      {:ok, _decl} = CUF.create_declaration(crew.id, [u1.id])

      summary = CUF.get_crew_cuf_summary(crew.id)
      assert summary.pending != nil
      assert summary.pending.participant_count == 1
      assert summary.total_validated_participants == 0
    end

    test "get_participant_stats/0 returns global stats", %{crew: crew, user1: u1} do
      {:ok, decl} = CUF.create_declaration(crew.id, [u1.id])
      admin = user_fixture(%{email: "admin2@test.com"})
      {:ok, _} = CUF.validate_declaration(decl, admin.id)

      stats = CUF.get_participant_stats()
      assert stats.validated >= 1
    end
  end

  describe "CUF exchange" do
    test "get_cuf_status/1 reflects received vs crew member count", %{crew: crew} do
      status = CUF.get_cuf_status(crew.id)
      assert status.received == 0
      assert status.needed == 2
      assert status.available == 0
      assert status.deficit == 2
    end

    test "update_received_count/2 updates the crew's count", %{crew: crew} do
      assert {:ok, updated} = CUF.update_received_count(crew, 5)
      assert updated.cuf_received_count == 5
      assert CUF.get_cuf_status(crew.id).received == 5
    end

    test "update_received_count/2 rejects negative counts", %{crew: crew} do
      assert {:error, changeset} = CUF.update_received_count(crew, -1)
      assert "must be greater than or equal to 0" in errors_on(changeset).cuf_received_count
    end

    test "upsert_exchange_listing/2 creates then updates the crew's one open listing", %{
      crew: crew
    } do
      assert {:ok, listing} =
               CUF.upsert_exchange_listing(crew.id, %{"kind" => "request", "quantity" => "1"})

      assert listing.kind == "request"
      assert listing.quantity == 1
      assert listing.status == "open"

      assert {:ok, updated} =
               CUF.upsert_exchange_listing(crew.id, %{"kind" => "offer", "quantity" => "2"})

      assert updated.id == listing.id
      assert updated.kind == "offer"
      assert updated.quantity == 2
      assert CUF.get_open_exchange_listing(crew.id).id == listing.id
    end

    test "an open offer is subtracted from the crew's available count", %{crew: crew} do
      {:ok, _} = CUF.update_received_count(crew, 3)
      {:ok, _} = CUF.upsert_exchange_listing(crew.id, %{"kind" => "offer", "quantity" => "1"})

      status = CUF.get_cuf_status(crew.id)
      assert status.received == 3
      assert status.available == 2
      assert status.deficit == 0
    end

    test "cancel_exchange_listing/1 closes the listing so a new one can be posted", %{
      crew: crew
    } do
      {:ok, listing} =
        CUF.upsert_exchange_listing(crew.id, %{"kind" => "request", "quantity" => "1"})

      assert {:ok, cancelled} = CUF.cancel_exchange_listing(listing)
      assert cancelled.status == "cancelled"
      assert CUF.get_open_exchange_listing(crew.id) == nil

      assert {:ok, new_listing} =
               CUF.upsert_exchange_listing(crew.id, %{"kind" => "offer", "quantity" => "1"})

      refute new_listing.id == listing.id
    end

    test "list_open_exchange_listings/2 lists other crews' open listings, can exclude one crew",
         %{crew: crew} do
      edition = Events.get_current_edition()
      other_user = user_fixture(%{email: "other-captain@test.com"})

      {:ok, %{crew: other_crew}} =
        Events.create_raft_with_crew(other_user, %{name: "Other Raft"}, edition.id)

      {:ok, _} = CUF.upsert_exchange_listing(crew.id, %{"kind" => "request", "quantity" => "1"})

      {:ok, _} =
        CUF.upsert_exchange_listing(other_crew.id, %{"kind" => "offer", "quantity" => "1"})

      all = CUF.list_open_exchange_listings(edition.id)
      assert length(all) == 2

      excluding_mine = CUF.list_open_exchange_listings(edition.id, crew.id)
      assert length(excluding_mine) == 1
      assert hd(excluding_mine).crew_id == other_crew.id
      assert hd(excluding_mine).crew.raft.name == "Other Raft"
    end

    test "transfer_cuf/4 moves CUFs between crews and records the transfer", %{
      crew: crew,
      user1: u1
    } do
      edition = Events.get_current_edition()
      other_user = user_fixture(%{email: "receiving-captain@test.com"})

      {:ok, %{crew: other_crew}} =
        Events.create_raft_with_crew(other_user, %{name: "Receiving Raft"}, edition.id)

      {:ok, _} = CUF.update_received_count(crew, 3)

      assert {:ok, %{transfer: transfer}} =
               CUF.transfer_cuf(crew.id, other_crew.id, 1, u1)

      assert transfer.quantity == 1
      assert CUF.get_cuf_status(crew.id).received == 2
      assert CUF.get_cuf_status(other_crew.id).received == 1

      [recorded] = CUF.list_crew_transfers(crew.id)
      assert recorded.id == transfer.id
      assert recorded.from_crew.raft.name == "CUF Test Raft"
      assert recorded.to_crew.raft.name == "Receiving Raft"
    end

    test "transfer_cuf/4 fails when the giving crew doesn't have enough", %{
      crew: crew,
      user1: u1
    } do
      edition = Events.get_current_edition()
      other_user = user_fixture(%{email: "receiving-captain2@test.com"})

      {:ok, %{crew: other_crew}} =
        Events.create_raft_with_crew(other_user, %{name: "Receiving Raft 2"}, edition.id)

      {:ok, _} = CUF.update_received_count(crew, 1)

      assert {:error, :updated_from, changeset, _changes} =
               CUF.transfer_cuf(crew.id, other_crew.id, 2, u1)

      assert "must be greater than or equal to 0" in errors_on(changeset).cuf_received_count
      assert CUF.get_cuf_status(crew.id).received == 1
      assert CUF.get_cuf_status(other_crew.id).received == 0
    end
  end
end
