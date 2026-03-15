defmodule HoMonRadeau.Drums.DrumSettingsTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Drums.DrumSettings

  @valid_attrs %{unit_price: Decimal.new("10.00")}

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = DrumSettings.changeset(%DrumSettings{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires unit_price" do
      changeset = DrumSettings.changeset(%DrumSettings{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).unit_price
    end

    test "validates unit_price must be greater than 0" do
      changeset = DrumSettings.changeset(%DrumSettings{}, %{unit_price: Decimal.new("0")})
      refute changeset.valid?
      assert %{unit_price: [_]} = errors_on(changeset)
    end

    test "rejects negative unit_price" do
      changeset = DrumSettings.changeset(%DrumSettings{}, %{unit_price: Decimal.new("-5")})
      refute changeset.valid?
      assert %{unit_price: [_]} = errors_on(changeset)
    end

    test "accepts positive unit_price" do
      changeset = DrumSettings.changeset(%DrumSettings{}, %{unit_price: Decimal.new("0.50")})
      assert changeset.valid?
    end

    test "casts rib_iban" do
      attrs = Map.put(@valid_attrs, :rib_iban, "FR7630006000011234567890189")
      changeset = DrumSettings.changeset(%DrumSettings{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :rib_iban) == "FR7630006000011234567890189"
    end

    test "casts rib_bic" do
      attrs = Map.put(@valid_attrs, :rib_bic, "BNPAFRPP")
      changeset = DrumSettings.changeset(%DrumSettings{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :rib_bic) == "BNPAFRPP"
    end
  end
end
