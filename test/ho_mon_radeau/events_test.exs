defmodule HoMonRadeau.EventsTest do
  use HoMonRadeau.DataCase

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.Edition

  describe "editions" do
    @valid_attrs %{year: 2026, name: "Tutto Blu 2026", is_current: true}
    @update_attrs %{name: "Updated Edition"}
    @invalid_attrs %{year: nil}

    def edition_fixture(attrs \\ %{}) do
      {:ok, edition} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_edition()

      edition
    end

    test "list_editions/0 returns all editions ordered by year desc" do
      _edition_2025 = edition_fixture(%{year: 2025, is_current: false})
      _edition_2026 = edition_fixture(%{year: 2026, is_current: true})

      editions = Events.list_editions()
      assert length(editions) == 2
      assert hd(editions).year == 2026
    end

    test "get_edition!/1 returns the edition with given id" do
      edition = edition_fixture()
      assert Events.get_edition!(edition.id) == edition
    end

    test "get_edition_by_year/1 returns the edition for given year" do
      edition = edition_fixture()
      assert Events.get_edition_by_year(2026) == edition
    end

    test "get_edition_by_year/1 returns nil for non-existent year" do
      assert Events.get_edition_by_year(9999) == nil
    end

    test "get_current_edition/0 returns the current edition" do
      edition_fixture(%{year: 2025, is_current: false})
      current = edition_fixture(%{year: 2026, is_current: true})

      assert Events.get_current_edition().id == current.id
    end

    test "get_current_edition/0 returns nil when no current edition" do
      edition_fixture(%{is_current: false})
      assert Events.get_current_edition() == nil
    end

    test "create_edition/1 with valid data creates an edition" do
      assert {:ok, %Edition{} = edition} = Events.create_edition(@valid_attrs)
      assert edition.year == 2026
      assert edition.name == "Tutto Blu 2026"
      assert edition.is_current == true
    end

    test "create_edition/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_edition(@invalid_attrs)
    end

    test "create_edition/1 enforces unique year constraint" do
      edition_fixture()
      assert {:error, changeset} = Events.create_edition(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).year
    end

    test "create_edition/1 with is_current true unsets other current editions" do
      first = edition_fixture(%{year: 2025, is_current: true})
      _second = edition_fixture(%{year: 2026, is_current: true})

      # Reload first edition
      first = Events.get_edition!(first.id)
      assert first.is_current == false
    end

    test "update_edition/2 with valid data updates the edition" do
      edition = edition_fixture()
      assert {:ok, %Edition{} = edition} = Events.update_edition(edition, @update_attrs)
      assert edition.name == "Updated Edition"
    end

    test "delete_edition/1 deletes the edition" do
      edition = edition_fixture()
      assert {:ok, %Edition{}} = Events.delete_edition(edition)
      assert_raise Ecto.NoResultsError, fn -> Events.get_edition!(edition.id) end
    end

    test "change_edition/1 returns a edition changeset" do
      edition = edition_fixture()
      assert %Ecto.Changeset{} = Events.change_edition(edition)
    end

    test "set_current_edition/1 sets edition as current and unsets others" do
      first = edition_fixture(%{year: 2025, is_current: true})
      second = edition_fixture(%{year: 2026, is_current: false})

      assert {:ok, updated_second} = Events.set_current_edition(second)
      assert updated_second.is_current == true

      # Reload first edition
      first = Events.get_edition!(first.id)
      assert first.is_current == false
    end

    test "get_or_create_current_edition/1 creates edition if not exists" do
      assert {:ok, edition} = Events.get_or_create_current_edition(2030)
      assert edition.year == 2030
      assert edition.is_current == true
    end

    test "get_or_create_current_edition/1 returns existing edition if current" do
      existing = edition_fixture(%{year: 2026, is_current: true})
      assert {:ok, edition} = Events.get_or_create_current_edition(2026)
      assert edition.id == existing.id
    end

    test "validates dates - end_date must be after start_date" do
      attrs = %{year: 2026, start_date: ~D[2026-08-15], end_date: ~D[2026-08-10]}
      assert {:error, changeset} = Events.create_edition(attrs)
      assert "must be after start date" in errors_on(changeset).end_date
    end
  end
end
