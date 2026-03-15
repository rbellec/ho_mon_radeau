defmodule HoMonRadeau.CUF.CUFSettingsTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.CUF.CUFSettings

  @valid_attrs %{unit_price: Decimal.new("5.00")}

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = CUFSettings.changeset(%CUFSettings{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires unit_price" do
      changeset = CUFSettings.changeset(%CUFSettings{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).unit_price
    end

    test "validates unit_price must be greater than 0" do
      changeset = CUFSettings.changeset(%CUFSettings{}, %{unit_price: Decimal.new("0")})
      refute changeset.valid?
      assert %{unit_price: [_]} = errors_on(changeset)
    end

    test "rejects negative unit_price" do
      changeset = CUFSettings.changeset(%CUFSettings{}, %{unit_price: Decimal.new("-1")})
      refute changeset.valid?
      assert %{unit_price: [_]} = errors_on(changeset)
    end

    test "accepts positive unit_price" do
      changeset = CUFSettings.changeset(%CUFSettings{}, %{unit_price: Decimal.new("0.01")})
      assert changeset.valid?
    end

    test "casts total_limit" do
      attrs = Map.put(@valid_attrs, :total_limit, 100)
      changeset = CUFSettings.changeset(%CUFSettings{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :total_limit) == 100
    end

    test "casts rib_iban" do
      attrs = Map.put(@valid_attrs, :rib_iban, "FR7630006000011234567890189")
      changeset = CUFSettings.changeset(%CUFSettings{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :rib_iban) == "FR7630006000011234567890189"
    end

    test "casts rib_bic" do
      attrs = Map.put(@valid_attrs, :rib_bic, "BNPAFRPP")
      changeset = CUFSettings.changeset(%CUFSettings{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :rib_bic) == "BNPAFRPP"
    end
  end
end
