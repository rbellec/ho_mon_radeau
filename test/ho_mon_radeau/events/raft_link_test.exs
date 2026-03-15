defmodule HoMonRadeau.Events.RaftLinkTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Events.RaftLink

  @valid_attrs %{raft_id: 1, title: "Our Playlist", url: "https://example.com/playlist"}

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = RaftLink.changeset(%RaftLink{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires raft_id" do
      attrs = Map.drop(@valid_attrs, [:raft_id])
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).raft_id
    end

    test "requires title" do
      attrs = Map.drop(@valid_attrs, [:title])
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
    end

    test "requires url" do
      attrs = Map.drop(@valid_attrs, [:url])
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).url
    end

    test "validates title max length of 200" do
      attrs = Map.put(@valid_attrs, :title, String.duplicate("a", 201))
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      refute changeset.valid?
      assert %{title: [_]} = errors_on(changeset)
    end

    test "accepts title at max length of 200" do
      attrs = Map.put(@valid_attrs, :title, String.duplicate("a", 200))
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      assert changeset.valid?
    end

    test "validates URL must have http or https scheme" do
      for bad_url <- ["ftp://example.com", "not-a-url", "javascript:alert(1)"] do
        attrs = Map.put(@valid_attrs, :url, bad_url)
        changeset = RaftLink.changeset(%RaftLink{}, attrs)
        refute changeset.valid?, "Expected #{bad_url} to be invalid"
        assert "must be a valid URL" in errors_on(changeset).url
      end
    end

    test "accepts valid http URL" do
      attrs = Map.put(@valid_attrs, :url, "http://example.com/page")
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      assert changeset.valid?
    end

    test "accepts valid https URL" do
      attrs = Map.put(@valid_attrs, :url, "https://example.com/page")
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      assert changeset.valid?
    end

    test "defaults position to 0" do
      changeset = RaftLink.changeset(%RaftLink{}, @valid_attrs)
      assert get_field(changeset, :position) == 0
    end

    test "accepts custom position" do
      attrs = Map.put(@valid_attrs, :position, 5)
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :position) == 5
    end

    test "defaults is_public to true" do
      changeset = RaftLink.changeset(%RaftLink{}, @valid_attrs)
      assert get_field(changeset, :is_public) == true
    end

    test "accepts is_public false" do
      attrs = Map.put(@valid_attrs, :is_public, false)
      changeset = RaftLink.changeset(%RaftLink{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :is_public) == false
    end
  end
end
