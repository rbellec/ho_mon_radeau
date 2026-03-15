defmodule HoMonRadeau.Events.CrewDepartureTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Events.CrewDeparture

  @valid_attrs %{user_id: 1, crew_id: 1}

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = CrewDeparture.changeset(%CrewDeparture{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires user_id" do
      changeset = CrewDeparture.changeset(%CrewDeparture{}, %{crew_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "requires crew_id" do
      changeset = CrewDeparture.changeset(%CrewDeparture{}, %{user_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).crew_id
    end

    test "removed_by_id is optional" do
      changeset = CrewDeparture.changeset(%CrewDeparture{}, @valid_attrs)
      assert changeset.valid?
      assert is_nil(get_field(changeset, :removed_by_id))
    end

    test "accepts removed_by_id" do
      attrs = Map.put(@valid_attrs, :removed_by_id, 42)
      changeset = CrewDeparture.changeset(%CrewDeparture{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :removed_by_id) == 42
    end

    test "defaults cuf_status_at_departure to none" do
      changeset = CrewDeparture.changeset(%CrewDeparture{}, @valid_attrs)
      assert get_field(changeset, :cuf_status_at_departure) == "none"
    end

    test "accepts cuf_status_at_departure" do
      attrs = Map.put(@valid_attrs, :cuf_status_at_departure, "paid")
      changeset = CrewDeparture.changeset(%CrewDeparture{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :cuf_status_at_departure) == "paid"
    end

    test "defaults was_captain to false" do
      changeset = CrewDeparture.changeset(%CrewDeparture{}, @valid_attrs)
      assert get_field(changeset, :was_captain) == false
    end

    test "accepts was_captain" do
      attrs = Map.put(@valid_attrs, :was_captain, true)
      changeset = CrewDeparture.changeset(%CrewDeparture{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :was_captain) == true
    end

    test "defaults was_manager to false" do
      changeset = CrewDeparture.changeset(%CrewDeparture{}, @valid_attrs)
      assert get_field(changeset, :was_manager) == false
    end

    test "accepts was_manager" do
      attrs = Map.put(@valid_attrs, :was_manager, true)
      changeset = CrewDeparture.changeset(%CrewDeparture{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :was_manager) == true
    end
  end
end
