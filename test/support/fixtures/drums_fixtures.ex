defmodule HoMonRadeau.DrumsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HoMonRadeau.Drums` context.
  """

  alias HoMonRadeau.Repo
  alias HoMonRadeau.Drums.{DrumSettings, DrumType, DrumDeclaration, DrumDeclarationLine}

  @doc """
  Creates drum settings with default or overridden attributes.
  """
  def drum_settings_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        forfait_price: Decimal.new("5.00")
      })

    %DrumSettings{}
    |> DrumSettings.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a drum type.
  """
  def drum_type_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Type #{System.unique_integer([:positive])}",
        unit_price: Decimal.new("5.00"),
        buoyancy_kg: 70,
        position: 1,
        active: true
      })

    %DrumType{}
    |> DrumType.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a drum declaration. Auto-creates a crew if not provided.
  """
  def drum_declaration_fixture(attrs \\ %{}) do
    crew_id = Map.get_lazy(attrs, :crew_id, fn -> create_crew!().id end)
    _settings = Repo.one(DrumSettings) || drum_settings_fixture()

    base = %{
      mode: "simple",
      total_quantity: 3,
      declared: true,
      declared_at: DateTime.utc_now(:second),
      status: "pending"
    }

    insert_attrs = Map.merge(base, Map.drop(attrs, [:crew_id]))

    %DrumDeclaration{crew_id: crew_id}
    |> Ecto.Changeset.cast(insert_attrs, [
      :mode,
      :total_quantity,
      :notes,
      :declared,
      :declared_at,
      :status,
      :total_amount,
      :paid_at,
      :validated_by_id
    ])
    |> Repo.insert!()
  end

  @doc """
  Creates a drum declaration line.
  """
  def drum_declaration_line_fixture(attrs) do
    attrs =
      Enum.into(attrs, %{
        quantity: 2,
        unit_price_snapshot: Decimal.new("5.00"),
        subtotal: Decimal.new("10.00")
      })

    %DrumDeclarationLine{}
    |> Ecto.Changeset.cast(attrs, [
      :declaration_id,
      :drum_type_id,
      :quantity,
      :unit_price_snapshot,
      :subtotal
    ])
    |> Repo.insert!()
  end

  defp create_crew! do
    alias HoMonRadeau.Events.{Edition, Raft, Crew}

    edition =
      %Edition{}
      |> Edition.changeset(%{year: System.unique_integer([:positive]) + 2100})
      |> Repo.insert!()

    raft =
      %Raft{}
      |> Raft.changeset(%{name: "Raft #{System.unique_integer()}", edition_id: edition.id})
      |> Repo.insert!()

    %Crew{}
    |> Crew.changeset(%{raft_id: raft.id, edition_id: edition.id})
    |> Repo.insert!()
  end
end
