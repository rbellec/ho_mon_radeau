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
end
