defmodule HoMonRadeau.Drums.DrumSettingsTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Drums.DrumSettings

  @valid_attrs %{forfait_price: Decimal.new("10.00")}

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = DrumSettings.changeset(%DrumSettings{}, @valid_attrs)
      assert changeset.valid?
    end

    test "valid even without forfait_price" do
      # forfait_price is optional now (no validate_required)
      changeset = DrumSettings.changeset(%DrumSettings{}, %{})
      assert changeset.valid?
    end

    test "validates forfait_price must be greater than 0" do
      changeset = DrumSettings.changeset(%DrumSettings{}, %{forfait_price: Decimal.new("0")})
      refute changeset.valid?
      assert %{forfait_price: [_]} = errors_on(changeset)
    end

    test "rejects negative forfait_price" do
      changeset = DrumSettings.changeset(%DrumSettings{}, %{forfait_price: Decimal.new("-5")})
      refute changeset.valid?
      assert %{forfait_price: [_]} = errors_on(changeset)
    end

    test "accepts positive forfait_price" do
      changeset = DrumSettings.changeset(%DrumSettings{}, %{forfait_price: Decimal.new("0.50")})
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
