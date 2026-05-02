defmodule HoMonRadeau.Integration.FinancialWorkflowsTest do
  use HoMonRadeau.DataCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures
  import HoMonRadeau.CUFFixtures
  import HoMonRadeau.DrumsFixtures

  alias HoMonRadeau.CUF
  alias HoMonRadeau.Drums
  alias HoMonRadeau.Events

  describe "CUF declaration lifecycle" do
    test "creates, validates, and tracks a CUF declaration for a crew" do
      # Step 1: Create CUF settings with unit price of 5.00
      cuf_settings_fixture(%{unit_price: Decimal.new("5.00")})

      # Step 2: Create a raft with crew and add 3 members
      edition = edition_fixture()
      manager = user_fixture()
      raft = raft_with_crew_fixture(%{user: manager, edition: edition})
      crew = Events.get_crew_by_raft(raft.id)

      member2 = user_fixture()
      member3 = user_fixture()
      {:ok, _} = Events.add_crew_member(crew.id, member2.id)
      {:ok, _} = Events.add_crew_member(crew.id, member3.id)

      participant_ids = [manager.id, member2.id, member3.id]

      # Step 3: Create a CUF declaration for the crew with participant_count = 3
      {:ok, declaration} = CUF.create_declaration(crew.id, participant_ids)

      # Step 4: Verify total_amount = 3 * 5.00 = 15.00
      assert declaration.participant_count == 3
      assert Decimal.equal?(declaration.total_amount, Decimal.new("15.00"))
      assert Decimal.equal?(declaration.unit_price, Decimal.new("5.00"))
      assert declaration.status == "pending"

      # Step 5: Verify the declaration appears in get_crew_cuf_summary/1
      summary = CUF.get_crew_cuf_summary(crew.id)
      assert length(summary.declarations) == 1
      assert summary.pending != nil
      assert summary.pending.id == declaration.id
      assert summary.total_validated_participants == 0

      # Step 6: An admin validates the declaration
      admin = user_fixture()

      {:ok, %{declaration: validated_declaration}} =
        CUF.validate_declaration(declaration, admin.id)

      # Step 7: Verify status is "validated"
      assert validated_declaration.status == "validated"
      assert validated_declaration.validated_by_id == admin.id
      assert validated_declaration.validated_at != nil

      # Step 8: Verify get_participant_stats/0 reflects the validated declaration
      stats = CUF.get_participant_stats()
      assert stats.validated == 3
    end
  end

  describe "Drum declaration lifecycle" do
    test "creates, validates payment, and tracks a drum declaration" do
      # Step 1: Create drum settings with forfait price
      drum_settings_fixture(%{forfait_price: Decimal.new("5.00")})

      # Step 2: Create a raft with crew
      edition = edition_fixture()
      manager = user_fixture()
      raft = raft_with_crew_fixture(%{user: manager, edition: edition})
      crew = Events.get_crew_by_raft(raft.id)

      # Step 3: Submit a simple declaration for 2 drums
      {:ok, declaration} =
        Drums.submit_declaration(crew.id, %{"mode" => "simple", "total_quantity" => "2"})

      assert declaration.declared
      assert declaration.mode == "simple"
      assert declaration.total_quantity == 2
      assert declaration.status == "pending"

      # Step 4: Admin validates payment
      admin = user_fixture()
      {:ok, paid} = Drums.validate_payment(declaration, admin.id)

      # Step 5: Verify status is "paid"
      assert paid.status == "paid"
      assert paid.validated_by_id == admin.id
      assert paid.paid_at != nil

      # Step 6: Re-submitting updates the same declaration
      {:ok, updated} =
        Drums.submit_declaration(crew.id, %{"mode" => "simple", "total_quantity" => "5"})

      assert updated.id == declaration.id
      assert updated.total_quantity == 5
    end
  end

  describe "CUF with member departure" do
    test "tracks CUF status when a member leaves and allows updated declarations" do
      # Step 1: Create crew with 3 members, declare CUF for 3
      cuf_settings_fixture(%{unit_price: Decimal.new("5.00")})
      edition = edition_fixture()
      manager = user_fixture()
      raft = raft_with_crew_fixture(%{user: manager, edition: edition})
      crew = Events.get_crew_by_raft(raft.id)

      member2 = user_fixture()
      member3 = user_fixture()
      {:ok, _} = Events.add_crew_member(crew.id, member2.id)
      {:ok, _} = Events.add_crew_member(crew.id, member3.id)

      participant_ids = [manager.id, member2.id, member3.id]
      {:ok, first_declaration} = CUF.create_declaration(crew.id, participant_ids)

      # Validate the declaration so participants get "confirmed" status
      admin = user_fixture()
      {:ok, _} = CUF.validate_declaration(first_declaration, admin.id)

      # Step 2: One member leaves the crew
      {:ok, %{departure: departure}} = Events.leave_crew(member3.id, crew.id)

      # Step 3: Verify the departure record has cuf_status_at_departure set
      assert departure.cuf_status_at_departure == "validated"
      assert departure.user_id == member3.id
      assert departure.crew_id == crew.id

      # Step 4: Create a new declaration with updated count (2)
      remaining_ids = [manager.id, member2.id]
      {:ok, second_declaration} = CUF.create_declaration(crew.id, remaining_ids)

      assert second_declaration.participant_count == 2
      assert Decimal.equal?(second_declaration.total_amount, Decimal.new("10.00"))

      # Step 5: Verify both declarations exist in history
      declarations = CUF.get_crew_declarations(crew.id)
      assert length(declarations) == 2

      declaration_ids = Enum.map(declarations, & &1.id)
      assert first_declaration.id in declaration_ids
      assert second_declaration.id in declaration_ids
    end
  end
end
