defmodule HoMonRadeau.Events.RaftTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Events.Raft

  @valid_attrs %{name: "The Blue Whale", edition_id: 1}

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = Raft.changeset(%Raft{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires name" do
      changeset = Raft.changeset(%Raft{}, %{edition_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "requires edition_id" do
      changeset = Raft.changeset(%Raft{}, %{name: "Test Raft"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).edition_id
    end

    test "validates name minimum length of 2" do
      changeset = Raft.changeset(%Raft{}, %{name: "A", edition_id: 1})
      refute changeset.valid?
      assert %{name: [_]} = errors_on(changeset)
    end

    test "validates name maximum length of 100" do
      long_name = String.duplicate("a", 101)
      changeset = Raft.changeset(%Raft{}, %{name: long_name, edition_id: 1})
      refute changeset.valid?
      assert %{name: [_]} = errors_on(changeset)
    end

    test "accepts name at boundary lengths" do
      changeset_min = Raft.changeset(%Raft{}, %{name: "AB", edition_id: 1})
      assert changeset_min.valid?

      changeset_max = Raft.changeset(%Raft{}, %{name: String.duplicate("a", 100), edition_id: 1})
      assert changeset_max.valid?
    end

    test "validates description_short maximum length of 150" do
      attrs = Map.merge(@valid_attrs, %{description_short: String.duplicate("a", 151)})
      changeset = Raft.changeset(%Raft{}, attrs)
      refute changeset.valid?
      assert %{description_short: [_]} = errors_on(changeset)
    end

    test "accepts description_short at 150 characters" do
      attrs = Map.merge(@valid_attrs, %{description_short: String.duplicate("a", 150)})
      changeset = Raft.changeset(%Raft{}, attrs)
      assert changeset.valid?
    end

    test "generates slug from name" do
      changeset = Raft.changeset(%Raft{}, @valid_attrs)
      assert get_change(changeset, :slug) == "the-blue-whale"
    end

    test "generates slug with special characters removed" do
      changeset = Raft.changeset(%Raft{}, %{name: "L'Arc-en-Ciel!", edition_id: 1})
      assert get_change(changeset, :slug) == "larc-en-ciel"
    end

    test "generates slug in lowercase" do
      changeset = Raft.changeset(%Raft{}, %{name: "MY RAFT", edition_id: 1})
      assert get_change(changeset, :slug) == "my-raft"
    end

    test "validates forum_url format" do
      attrs = Map.merge(@valid_attrs, %{forum_url: "not-a-url"})
      changeset = Raft.changeset(%Raft{}, attrs)
      refute changeset.valid?
      assert "must be a valid URL" in errors_on(changeset).forum_url
    end

    test "accepts valid forum_url" do
      attrs = Map.merge(@valid_attrs, %{forum_url: "https://forum.example.com/topic/1"})
      changeset = Raft.changeset(%Raft{}, attrs)
      assert changeset.valid?
    end
  end

  describe "validation_changeset/2" do
    test "casts validated field" do
      changeset = Raft.validation_changeset(%Raft{}, %{validated: true})
      assert get_change(changeset, :validated) == true
    end

    test "casts validated_at field" do
      now = DateTime.utc_now(:second)
      changeset = Raft.validation_changeset(%Raft{}, %{validated_at: now})
      assert get_change(changeset, :validated_at) == now
    end

    test "casts validated_by_id field" do
      changeset = Raft.validation_changeset(%Raft{}, %{validated_by_id: 42})
      assert get_change(changeset, :validated_by_id) == 42
    end
  end

  describe "update_changeset/2" do
    test "casts description" do
      changeset = Raft.update_changeset(%Raft{}, %{description: "A great raft"})
      assert get_change(changeset, :description) == "A great raft"
    end

    test "casts description_short" do
      changeset = Raft.update_changeset(%Raft{}, %{description_short: "Short desc"})
      assert get_change(changeset, :description_short) == "Short desc"
    end

    test "casts forum_url" do
      changeset = Raft.update_changeset(%Raft{}, %{forum_url: "https://forum.example.com"})
      assert get_change(changeset, :forum_url) == "https://forum.example.com"
    end

    test "casts picture_url" do
      changeset =
        Raft.update_changeset(%Raft{}, %{picture_url: "https://img.example.com/pic.jpg"})

      assert get_change(changeset, :picture_url) == "https://img.example.com/pic.jpg"
    end

    test "does not allow name change" do
      changeset = Raft.update_changeset(%Raft{name: "Old Name"}, %{name: "New Name"})
      refute Map.has_key?(changeset.changes, :name)
    end

    test "validates description_short max length" do
      changeset = Raft.update_changeset(%Raft{}, %{description_short: String.duplicate("a", 151)})
      refute changeset.valid?
      assert %{description_short: [_]} = errors_on(changeset)
    end

    test "validates forum_url format" do
      changeset = Raft.update_changeset(%Raft{}, %{forum_url: "bad-url"})
      refute changeset.valid?
      assert "must be a valid URL" in errors_on(changeset).forum_url
    end
  end
end
