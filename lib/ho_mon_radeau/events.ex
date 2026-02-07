defmodule HoMonRadeau.Events do
  @moduledoc """
  The Events context.
  Manages editions, rafts, crews, and related entities.
  """

  import Ecto.Query, warn: false
  alias HoMonRadeau.Repo
  alias HoMonRadeau.Events.Edition

  ## Editions

  @doc """
  Returns the list of all editions.
  """
  def list_editions do
    Edition
    |> order_by([e], desc: e.year)
    |> Repo.all()
  end

  @doc """
  Gets a single edition.
  Raises `Ecto.NoResultsError` if the Edition does not exist.
  """
  def get_edition!(id), do: Repo.get!(Edition, id)

  @doc """
  Gets an edition by year.
  Returns nil if not found.
  """
  def get_edition_by_year(year) when is_integer(year) do
    Repo.get_by(Edition, year: year)
  end

  @doc """
  Gets the current edition (is_current = true).
  Returns nil if no current edition is set.
  """
  def get_current_edition do
    Repo.get_by(Edition, is_current: true)
  end

  @doc """
  Gets or creates the current edition for the given year.
  If no edition exists for the year, creates one.
  If an edition exists but is not current, makes it current.
  """
  def get_or_create_current_edition(year \\ nil) do
    year = year || Date.utc_today().year

    case get_edition_by_year(year) do
      nil ->
        create_edition(%{year: year, name: "Tutto Blu #{year}", is_current: true})

      edition ->
        if edition.is_current do
          {:ok, edition}
        else
          set_current_edition(edition)
        end
    end
  end

  @doc """
  Creates an edition.
  """
  def create_edition(attrs \\ %{}) do
    %Edition{}
    |> Edition.changeset(attrs)
    |> maybe_unset_other_current(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an edition.
  """
  def update_edition(%Edition{} = edition, attrs) do
    edition
    |> Edition.changeset(attrs)
    |> maybe_unset_other_current(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an edition.
  """
  def delete_edition(%Edition{} = edition) do
    Repo.delete(edition)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking edition changes.
  """
  def change_edition(%Edition{} = edition, attrs \\ %{}) do
    Edition.changeset(edition, attrs)
  end

  @doc """
  Sets an edition as the current one, unsetting any other current edition.
  """
  def set_current_edition(%Edition{} = edition) do
    Repo.transaction(fn ->
      # Unset all other current editions
      from(e in Edition, where: e.is_current == true and e.id != ^edition.id)
      |> Repo.update_all(set: [is_current: false])

      # Set this edition as current
      edition
      |> Edition.changeset(%{is_current: true})
      |> Repo.update!()
    end)
  end

  # If setting is_current to true, unset all other current editions
  defp maybe_unset_other_current(changeset, attrs) do
    if Map.get(attrs, :is_current) == true || Map.get(attrs, "is_current") == true do
      Ecto.Changeset.prepare_changes(changeset, fn changeset ->
        from(e in Edition, where: e.is_current == true)
        |> changeset.repo.update_all(set: [is_current: false])

        changeset
      end)
    else
      changeset
    end
  end
end
