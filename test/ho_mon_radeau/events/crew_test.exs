defmodule HoMonRadeau.Events.CrewTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Events.Crew

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = Crew.changeset(%Crew{}, %{raft_id: 1, edition_id: 1})
      assert changeset.valid?
    end

    test "requires raft_id" do
      changeset = Crew.changeset(%Crew{}, %{edition_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).raft_id
    end

    test "requires edition_id" do
      changeset = Crew.changeset(%Crew{}, %{raft_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).edition_id
    end

    test "does not cast name or description" do
      changeset =
        Crew.changeset(%Crew{}, %{
          raft_id: 1,
          edition_id: 1,
          name: "Ignored",
          description: "Also ignored"
        })

      refute Map.has_key?(changeset.changes, :name)
      refute Map.has_key?(changeset.changes, :description)
    end
  end

  describe "transverse_changeset/2" do
    test "valid with required fields and valid type" do
      changeset =
        Crew.transverse_changeset(%Crew{}, %{
          name: "Welcome Team",
          transverse_type: "welcome_team"
        })

      assert changeset.valid?
    end

    test "requires name" do
      changeset = Crew.transverse_changeset(%Crew{}, %{transverse_type: "welcome_team"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "requires transverse_type" do
      changeset = Crew.transverse_changeset(%Crew{}, %{name: "Some Team"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).transverse_type
    end

    test "sets is_transverse to true" do
      changeset =
        Crew.transverse_changeset(%Crew{}, %{
          name: "Welcome Team",
          transverse_type: "welcome_team"
        })

      assert get_change(changeset, :is_transverse) == true
    end

    test "forces is_transverse to true even if passed as false" do
      changeset =
        Crew.transverse_changeset(%Crew{}, %{
          name: "Welcome Team",
          transverse_type: "welcome_team",
          is_transverse: false
        })

      assert get_change(changeset, :is_transverse) == true
    end

    test "validates transverse_type inclusion" do
      changeset =
        Crew.transverse_changeset(%Crew{}, %{name: "Bad Team", transverse_type: "invalid_type"})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).transverse_type
    end

    test "accepts all valid transverse types" do
      for type <- Crew.transverse_types() do
        changeset =
          Crew.transverse_changeset(%Crew{}, %{name: "Team #{type}", transverse_type: type})

        assert changeset.valid?, "Expected transverse_type '#{type}' to be valid"
      end
    end

    test "validates name minimum length of 2" do
      changeset = Crew.transverse_changeset(%Crew{}, %{name: "A", transverse_type: "other"})
      refute changeset.valid?
      assert %{name: [_]} = errors_on(changeset)
    end

    test "validates name maximum length of 100" do
      changeset =
        Crew.transverse_changeset(%Crew{}, %{
          name: String.duplicate("a", 101),
          transverse_type: "other"
        })

      refute changeset.valid?
      assert %{name: [_]} = errors_on(changeset)
    end
  end

  describe "transverse_types/0" do
    test "returns the list of valid transverse types" do
      types = Crew.transverse_types()
      assert is_list(types)
      assert "welcome_team" in types
      assert "safe_team" in types
      assert "drums_team" in types
      assert "security" in types
      assert "medical" in types
      assert "other" in types
      assert length(types) == 6
    end
  end
end
