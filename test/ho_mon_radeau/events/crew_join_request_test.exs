defmodule HoMonRadeau.Events.CrewJoinRequestTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Events.CrewJoinRequest

  @valid_attrs %{crew_id: 1, user_id: 1}

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = CrewJoinRequest.changeset(%CrewJoinRequest{}, @valid_attrs)
      assert changeset.valid?
    end

    test "valid with optional message" do
      attrs = Map.put(@valid_attrs, :message, "I'd love to join!")
      changeset = CrewJoinRequest.changeset(%CrewJoinRequest{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :message) == "I'd love to join!"
    end

    test "requires crew_id" do
      changeset = CrewJoinRequest.changeset(%CrewJoinRequest{}, %{user_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).crew_id
    end

    test "requires user_id" do
      changeset = CrewJoinRequest.changeset(%CrewJoinRequest{}, %{crew_id: 1})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "status defaults to pending and changeset does not cast status" do
      changeset = CrewJoinRequest.changeset(%CrewJoinRequest{}, @valid_attrs)
      # status is not cast by changeset/2, so it stays at schema default
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end
  end

  describe "response_changeset/2" do
    test "sets responded_at when status is accepted" do
      changeset =
        CrewJoinRequest.response_changeset(%CrewJoinRequest{status: "pending"}, %{
          status: "accepted",
          responded_by_id: 42
        })

      assert changeset.valid?
      assert get_change(changeset, :responded_at)
    end

    test "sets responded_at when status is rejected" do
      changeset =
        CrewJoinRequest.response_changeset(%CrewJoinRequest{status: "pending"}, %{
          status: "rejected",
          responded_by_id: 42
        })

      assert changeset.valid?
      assert get_change(changeset, :responded_at)
    end

    test "does not set responded_at for pending status" do
      changeset =
        CrewJoinRequest.response_changeset(%CrewJoinRequest{status: "pending"}, %{
          status: "pending"
        })

      assert changeset.valid?
      refute get_change(changeset, :responded_at)
    end

    test "does not set responded_at for cancelled status" do
      changeset =
        CrewJoinRequest.response_changeset(%CrewJoinRequest{status: "pending"}, %{
          status: "cancelled"
        })

      assert changeset.valid?
      refute get_change(changeset, :responded_at)
    end

    test "validates status inclusion" do
      changeset =
        CrewJoinRequest.response_changeset(%CrewJoinRequest{}, %{status: "bogus"})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).status
    end
  end

  describe "statuses/0" do
    test "returns expected list" do
      assert CrewJoinRequest.statuses() == ~w(pending accepted rejected cancelled)
    end
  end
end
