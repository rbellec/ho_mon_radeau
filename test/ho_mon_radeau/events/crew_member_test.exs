defmodule HoMonRadeau.Events.CrewMemberTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Events.CrewMember

  @valid_attrs %{crew_id: 1, user_id: 1}

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = CrewMember.changeset(%CrewMember{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires crew_id" do
      changeset = CrewMember.changeset(%CrewMember{}, %{user_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).crew_id
    end

    test "requires user_id" do
      changeset = CrewMember.changeset(%CrewMember{}, %{crew_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "validates roles contain only valid values" do
      attrs = Map.merge(@valid_attrs, %{roles: ["lead_construction", "invalid_role"]})
      changeset = CrewMember.changeset(%CrewMember{}, attrs)
      refute changeset.valid?
      assert %{roles: [msg]} = errors_on(changeset)
      assert msg =~ "invalid roles"
    end

    test "accepts valid roles" do
      attrs = Map.merge(@valid_attrs, %{roles: ["lead_construction", "cooking", "music"]})
      changeset = CrewMember.changeset(%CrewMember{}, attrs)
      assert changeset.valid?
    end

    test "accepts empty roles list" do
      attrs = Map.merge(@valid_attrs, %{roles: []})
      changeset = CrewMember.changeset(%CrewMember{}, attrs)
      assert changeset.valid?
    end

    test "auto-sets joined_at when crew_id is provided" do
      changeset = CrewMember.changeset(%CrewMember{}, @valid_attrs)
      assert get_change(changeset, :joined_at) != nil
    end

    test "does not overwrite existing joined_at" do
      existing_time = ~U[2025-01-01 00:00:00Z]
      member = %CrewMember{joined_at: existing_time}
      changeset = CrewMember.changeset(member, @valid_attrs)
      assert get_field(changeset, :joined_at) == existing_time
    end

    test "validates participation_status inclusion" do
      attrs = Map.merge(@valid_attrs, %{participation_status: "unknown"})
      changeset = CrewMember.changeset(%CrewMember{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).participation_status
    end

    test "accepts valid participation statuses" do
      for status <- ~w(pending confirmed declined) do
        attrs = Map.merge(@valid_attrs, %{participation_status: status})
        changeset = CrewMember.changeset(%CrewMember{}, attrs)
        assert changeset.valid?, "Expected status '#{status}' to be valid"
      end
    end
  end

  describe "update_changeset/2" do
    test "casts is_manager" do
      changeset = CrewMember.update_changeset(%CrewMember{}, %{is_manager: true})
      assert get_change(changeset, :is_manager) == true
    end

    test "casts is_captain" do
      changeset = CrewMember.update_changeset(%CrewMember{}, %{is_captain: true})
      assert get_change(changeset, :is_captain) == true
    end

    test "casts roles" do
      changeset = CrewMember.update_changeset(%CrewMember{}, %{roles: ["cooking"]})
      assert get_change(changeset, :roles) == ["cooking"]
    end

    test "casts participation_status" do
      changeset = CrewMember.update_changeset(%CrewMember{}, %{participation_status: "confirmed"})
      assert get_change(changeset, :participation_status) == "confirmed"
    end

    test "does not cast crew_id or user_id" do
      changeset = CrewMember.update_changeset(%CrewMember{}, %{crew_id: 99, user_id: 99})
      refute Map.has_key?(changeset.changes, :crew_id)
      refute Map.has_key?(changeset.changes, :user_id)
    end

    test "validates roles in update" do
      changeset = CrewMember.update_changeset(%CrewMember{}, %{roles: ["bad_role"]})
      refute changeset.valid?
    end

    test "validates participation_status in update" do
      changeset = CrewMember.update_changeset(%CrewMember{}, %{participation_status: "nope"})
      refute changeset.valid?
    end
  end

  describe "promote_to_manager_changeset/1" do
    test "sets is_manager to true" do
      changeset = CrewMember.promote_to_manager_changeset(%CrewMember{is_manager: false})
      assert get_change(changeset, :is_manager) == true
    end
  end

  describe "demote_from_manager_changeset/1" do
    test "sets is_manager to false" do
      changeset = CrewMember.demote_from_manager_changeset(%CrewMember{is_manager: true})
      assert get_change(changeset, :is_manager) == false
    end
  end

  describe "set_captain_changeset/2" do
    test "sets is_captain to true" do
      changeset = CrewMember.set_captain_changeset(%CrewMember{}, true)
      assert get_change(changeset, :is_captain) == true
    end

    test "sets is_captain to false" do
      changeset = CrewMember.set_captain_changeset(%CrewMember{is_captain: true}, false)
      assert get_change(changeset, :is_captain) == false
    end
  end

  describe "valid_roles/0" do
    test "returns all valid roles" do
      roles = CrewMember.valid_roles()
      assert "lead_construction" in roles
      assert "cooking" in roles
      assert "safe_contact" in roles
      assert "logistics" in roles
      assert "music" in roles
      assert "decoration" in roles
      assert "other" in roles
    end
  end

  describe "required_roles/0" do
    test "returns required roles" do
      roles = CrewMember.required_roles()
      assert roles == ~w(lead_construction cooking safe_contact)
    end
  end

  describe "optional_roles/0" do
    test "returns optional roles" do
      roles = CrewMember.optional_roles()
      assert roles == ~w(logistics music decoration other)
    end
  end
end
