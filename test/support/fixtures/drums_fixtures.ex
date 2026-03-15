defmodule HoMonRadeau.DrumsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HoMonRadeau.Drums` context.
  """

  alias HoMonRadeau.Repo
  alias HoMonRadeau.Drums.{DrumSettings, DrumRequest}

  @doc """
  Creates drum settings with default or overridden attributes.
  """
  def drum_settings_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        unit_price: Decimal.new("5.00")
      })

    %DrumSettings{}
    |> DrumSettings.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a drum request. Auto-creates a crew and drum settings if not provided.
  """
  def drum_request_fixture(attrs \\ %{}) do
    crew_id = Map.get_lazy(attrs, :crew_id, fn -> create_crew!().id end)
    settings = Repo.one(DrumSettings) || drum_settings_fixture()

    quantity = Map.get(attrs, :quantity, 2)
    total_amount = Decimal.mult(Decimal.new(quantity), settings.unit_price)

    insert_attrs =
      Map.merge(
        %{
          quantity: quantity,
          unit_price: settings.unit_price,
          total_amount: total_amount,
          status: "pending"
        },
        Map.drop(attrs, [:crew_id, :quantity])
      )

    %DrumRequest{crew_id: crew_id}
    |> Ecto.Changeset.cast(insert_attrs, [
      :quantity,
      :unit_price,
      :total_amount,
      :status,
      :note,
      :paid_at,
      :validated_by_id
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
