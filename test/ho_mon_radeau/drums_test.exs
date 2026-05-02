defmodule HoMonRadeau.DrumsTest do
  use HoMonRadeau.DataCase

  alias HoMonRadeau.Drums
  alias HoMonRadeau.Events

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.DrumsFixtures

  setup do
    user = user_fixture()

    user =
      user
      |> Ecto.Changeset.change(validated: true)
      |> Repo.update!()

    {:ok, edition} = Events.get_or_create_current_edition()

    {:ok, %{crew: crew}} =
      Events.create_raft_with_crew(user, %{name: "Test Raft"}, edition.id)

    %{user: user, crew: crew}
  end

  describe "settings" do
    test "get_settings/0 returns defaults when no settings exist" do
      settings = Drums.get_settings()
      assert Decimal.equal?(settings.forfait_price, Decimal.new(5))
    end

    test "update_settings/1 creates or updates settings" do
      assert {:ok, settings} =
               Drums.update_settings(%{forfait_price: "7.50", rib_iban: "FR76123"})

      assert Decimal.equal?(settings.forfait_price, Decimal.new("7.50"))
      assert settings.rib_iban == "FR76123"
    end
  end

  describe "drum types" do
    test "create_drum_type/1 creates a type" do
      assert {:ok, type} =
               Drums.create_drum_type(%{name: "Test 100L", buoyancy_kg: 25, position: 1})

      assert type.name == "Test 100L"
      assert type.buoyancy_kg == 25
      assert type.active == true
    end

    test "list_drum_types/0 returns types ordered by position" do
      _t1 = drum_type_fixture(name: "ZZZ", position: 99)
      _t2 = drum_type_fixture(name: "AAA", position: 0)
      types = Drums.list_drum_types()
      # Position 0 (AAA) should come first
      assert Enum.at(types, 0).name == "AAA"
      # Position 99 (ZZZ) should come last
      assert List.last(types).name == "ZZZ"
    end
  end

  describe "declarations" do
    test "get_or_build_declaration/1 returns empty struct when none exists", %{crew: crew} do
      decl = Drums.get_or_build_declaration(crew.id)
      assert decl.crew_id == crew.id
      refute decl.declared
      assert decl.lines == []
    end

    test "submit_declaration/2 in simple mode marks as declared", %{crew: crew} do
      assert {:ok, decl} =
               Drums.submit_declaration(crew.id, %{"mode" => "simple", "total_quantity" => "5"})

      assert decl.declared
      assert decl.declared_at
      assert decl.mode == "simple"
      assert decl.total_quantity == 5
    end

    test "submit_declaration/2 with 0 quantity is valid (deliberate no-bidons)", %{crew: crew} do
      assert {:ok, decl} =
               Drums.submit_declaration(crew.id, %{"mode" => "simple", "total_quantity" => "0"})

      assert decl.declared
      assert decl.total_quantity == 0
    end

    test "submit_declaration/2 in specific mode creates lines", %{crew: crew} do
      _settings = drum_settings_fixture()
      type1 = drum_type_fixture(name: "Type 1", unit_price: Decimal.new("4.00"))
      type2 = drum_type_fixture(name: "Type 2", unit_price: Decimal.new("6.00"))

      attrs = %{
        "mode" => "specific",
        "lines" => %{
          Integer.to_string(type1.id) => "3",
          Integer.to_string(type2.id) => "2"
        }
      }

      assert {:ok, decl} = Drums.submit_declaration(crew.id, attrs)
      decl = Repo.preload(decl, :lines)

      assert decl.declared
      assert decl.mode == "specific"

      # Lines created for all active types (seeded + custom). Check our two have correct quantities.
      lines_by_type = Map.new(decl.lines, fn l -> {l.drum_type_id, l.quantity} end)
      assert lines_by_type[type1.id] == 3
      assert lines_by_type[type2.id] == 2
    end

    test "submit_declaration/2 updates existing declaration on second call", %{crew: crew} do
      {:ok, decl1} =
        Drums.submit_declaration(crew.id, %{"mode" => "simple", "total_quantity" => "3"})

      {:ok, decl2} =
        Drums.submit_declaration(crew.id, %{"mode" => "simple", "total_quantity" => "8"})

      assert decl1.id == decl2.id
      assert decl2.total_quantity == 8
    end

    test "validate_payment/2 marks declaration as paid", %{crew: crew, user: user} do
      {:ok, decl} =
        Drums.submit_declaration(crew.id, %{"mode" => "simple", "total_quantity" => "3"})

      assert {:ok, paid} = Drums.validate_payment(decl, user.id)
      assert paid.status == "paid"
      assert paid.paid_at
      assert paid.validated_by_id == user.id
    end

    test "list_all_declarations/0 returns declarations with raft preloaded", %{crew: crew} do
      {:ok, _} = Drums.submit_declaration(crew.id, %{"mode" => "simple", "total_quantity" => "2"})

      declarations = Drums.list_all_declarations()
      assert length(declarations) == 1
      assert hd(declarations).crew.raft.name == "Test Raft"
    end
  end
end
