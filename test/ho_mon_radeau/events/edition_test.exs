defmodule HoMonRadeau.Events.EditionTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Events.Edition

  @valid_attrs %{year: 2025}

  describe "changeset/2" do
    test "valid with only required fields" do
      changeset = Edition.changeset(%Edition{}, @valid_attrs)
      assert changeset.valid?
    end

    test "valid with all fields" do
      attrs = %{
        year: 2025,
        name: "Tutto Blu 2025",
        is_current: true,
        start_date: ~D[2025-07-01],
        end_date: ~D[2025-07-15],
        registration_deadline: ~D[2025-06-01],
        participant_form_url: "https://forms.example.com/participant",
        captain_form_url: "https://forms.example.com/captain"
      }

      changeset = Edition.changeset(%Edition{}, attrs)
      assert changeset.valid?
    end

    test "requires year" do
      changeset = Edition.changeset(%Edition{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).year
    end

    test "validates year must be greater than 2000" do
      changeset = Edition.changeset(%Edition{}, %{year: 2000})
      refute changeset.valid?
      assert %{year: [_]} = errors_on(changeset)
    end

    test "validates year must be less than 3000" do
      changeset = Edition.changeset(%Edition{}, %{year: 3000})
      refute changeset.valid?
      assert %{year: [_]} = errors_on(changeset)
    end

    test "accepts year within valid range" do
      for year <- [2001, 2025, 2999] do
        changeset = Edition.changeset(%Edition{}, %{year: year})
        assert changeset.valid?, "Expected year #{year} to be valid"
      end
    end

    test "validates end_date must be after start_date" do
      attrs =
        Map.merge(@valid_attrs, %{
          start_date: ~D[2025-07-15],
          end_date: ~D[2025-07-01]
        })

      changeset = Edition.changeset(%Edition{}, attrs)
      refute changeset.valid?
      assert "must be after start date" in errors_on(changeset).end_date
    end

    test "accepts end_date equal to start_date" do
      attrs =
        Map.merge(@valid_attrs, %{
          start_date: ~D[2025-07-01],
          end_date: ~D[2025-07-01]
        })

      changeset = Edition.changeset(%Edition{}, attrs)
      assert changeset.valid?
    end

    test "accepts end_date after start_date" do
      attrs =
        Map.merge(@valid_attrs, %{
          start_date: ~D[2025-07-01],
          end_date: ~D[2025-07-15]
        })

      changeset = Edition.changeset(%Edition{}, attrs)
      assert changeset.valid?
    end

    test "accepts nil dates" do
      changeset = Edition.changeset(%Edition{}, @valid_attrs)
      assert changeset.valid?
      assert is_nil(get_field(changeset, :start_date))
      assert is_nil(get_field(changeset, :end_date))
    end

    test "validates participant_form_url format" do
      attrs = Map.merge(@valid_attrs, %{participant_form_url: "not-a-url"})
      changeset = Edition.changeset(%Edition{}, attrs)
      refute changeset.valid?
      assert "must be a valid URL" in errors_on(changeset).participant_form_url
    end

    test "validates captain_form_url format" do
      attrs = Map.merge(@valid_attrs, %{captain_form_url: "ftp://invalid.com"})
      changeset = Edition.changeset(%Edition{}, attrs)
      refute changeset.valid?
      assert "must be a valid URL" in errors_on(changeset).captain_form_url
    end

    test "accepts valid http URL for participant_form_url" do
      attrs = Map.merge(@valid_attrs, %{participant_form_url: "http://forms.example.com"})
      changeset = Edition.changeset(%Edition{}, attrs)
      assert changeset.valid?
    end

    test "accepts valid https URL for captain_form_url" do
      attrs = Map.merge(@valid_attrs, %{captain_form_url: "https://forms.example.com/captain"})
      changeset = Edition.changeset(%Edition{}, attrs)
      assert changeset.valid?
    end
  end
end
