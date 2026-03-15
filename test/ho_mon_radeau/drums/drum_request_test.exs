defmodule HoMonRadeau.Drums.DrumRequestTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Drums.DrumRequest

  @unit_price Decimal.new("10.00")

  describe "changeset/3" do
    test "valid with required fields" do
      changeset = DrumRequest.changeset(%DrumRequest{}, %{quantity: 3}, @unit_price)
      assert changeset.valid?
    end

    test "requires quantity" do
      changeset = DrumRequest.changeset(%DrumRequest{}, %{}, @unit_price)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).quantity
    end

    test "validates quantity must be >= 0" do
      changeset = DrumRequest.changeset(%DrumRequest{}, %{quantity: -1}, @unit_price)
      refute changeset.valid?
      assert %{quantity: [_]} = errors_on(changeset)
    end

    test "accepts quantity of 0" do
      changeset = DrumRequest.changeset(%DrumRequest{}, %{quantity: 0}, @unit_price)
      assert changeset.valid?
    end

    test "calculates total_amount from quantity and unit_price" do
      changeset = DrumRequest.changeset(%DrumRequest{}, %{quantity: 5}, @unit_price)
      assert changeset.valid?
      assert get_change(changeset, :total_amount) == Decimal.mult(Decimal.new(5), @unit_price)
    end

    test "stores unit_price in the changeset" do
      changeset = DrumRequest.changeset(%DrumRequest{}, %{quantity: 2}, @unit_price)
      assert get_change(changeset, :unit_price) == @unit_price
    end

    test "does not calculate amounts when quantity is nil" do
      changeset = DrumRequest.changeset(%DrumRequest{}, %{}, @unit_price)
      refute get_change(changeset, :total_amount)
      refute get_change(changeset, :unit_price)
    end

    test "casts optional note" do
      attrs = %{quantity: 1, note: "Extra drums please"}
      changeset = DrumRequest.changeset(%DrumRequest{}, attrs, @unit_price)
      assert changeset.valid?
      assert get_change(changeset, :note) == "Extra drums please"
    end
  end

  describe "payment_changeset/2" do
    test "sets status to paid with validator info" do
      changeset = DrumRequest.payment_changeset(%DrumRequest{}, 42)
      assert get_change(changeset, :status) == "paid"
      assert get_change(changeset, :validated_by_id) == 42
      assert get_change(changeset, :paid_at)
    end
  end

  describe "statuses/0" do
    test "returns expected list" do
      assert DrumRequest.statuses() == ~w(pending paid)
    end
  end
end
