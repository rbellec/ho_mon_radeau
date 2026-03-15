defmodule HoMonRadeau.CUF.DeclarationTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.CUF.Declaration

  @unit_price Decimal.new("5.00")

  describe "changeset/3" do
    test "valid with required fields" do
      changeset = Declaration.changeset(%Declaration{}, %{participant_count: 3}, @unit_price)
      assert changeset.valid?
    end

    test "requires participant_count" do
      changeset = Declaration.changeset(%Declaration{}, %{}, @unit_price)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).participant_count
    end

    test "validates participant_count must be greater than 0" do
      changeset = Declaration.changeset(%Declaration{}, %{participant_count: 0}, @unit_price)
      refute changeset.valid?
      assert %{participant_count: [_]} = errors_on(changeset)
    end

    test "rejects negative participant_count" do
      changeset = Declaration.changeset(%Declaration{}, %{participant_count: -1}, @unit_price)
      refute changeset.valid?
      assert %{participant_count: [_]} = errors_on(changeset)
    end

    test "calculates total_amount from participant_count and unit_price" do
      changeset = Declaration.changeset(%Declaration{}, %{participant_count: 4}, @unit_price)
      assert changeset.valid?
      assert get_change(changeset, :total_amount) == Decimal.mult(Decimal.new(4), @unit_price)
    end

    test "stores unit_price in the changeset" do
      changeset = Declaration.changeset(%Declaration{}, %{participant_count: 2}, @unit_price)
      assert get_change(changeset, :unit_price) == @unit_price
    end

    test "does not calculate amounts when participant_count is nil" do
      changeset = Declaration.changeset(%Declaration{}, %{}, @unit_price)
      refute get_change(changeset, :total_amount)
      refute get_change(changeset, :unit_price)
    end

    test "casts participant_user_ids" do
      attrs = %{participant_count: 2, participant_user_ids: [10, 20]}
      changeset = Declaration.changeset(%Declaration{}, attrs, @unit_price)
      assert changeset.valid?
      assert get_change(changeset, :participant_user_ids) == [10, 20]
    end
  end

  describe "validation_changeset/2" do
    test "sets status to validated with validator info" do
      changeset = Declaration.validation_changeset(%Declaration{}, 42)
      assert get_change(changeset, :status) == "validated"
      assert get_change(changeset, :validated_by_id) == 42
      assert get_change(changeset, :validated_at)
    end
  end
end
