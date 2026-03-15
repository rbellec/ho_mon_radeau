defmodule HoMonRadeau.CUFFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HoMonRadeau.CUF` context.
  """

  alias HoMonRadeau.Repo
  alias HoMonRadeau.CUF.{CUFSettings, Declaration}

  @doc """
  Creates CUF settings with default or overridden attributes.
  """
  def cuf_settings_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        unit_price: Decimal.new("5.00")
      })

    %CUFSettings{}
    |> CUFSettings.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a declaration. Auto-creates a crew and CUF settings if not provided.
  """
  def declaration_fixture(attrs \\ %{}) do
    crew_id = Map.get_lazy(attrs, :crew_id, fn -> create_crew!().id end)
    settings = Repo.one(CUFSettings) || cuf_settings_fixture()

    participant_count = Map.get(attrs, :participant_count, 3)
    participant_user_ids = Map.get(attrs, :participant_user_ids, [])

    total_amount =
      Decimal.mult(Decimal.new(participant_count), settings.unit_price)

    insert_attrs =
      Map.merge(
        %{
          participant_count: participant_count,
          participant_user_ids: participant_user_ids,
          unit_price: settings.unit_price,
          total_amount: total_amount,
          status: "pending"
        },
        Map.drop(attrs, [:crew_id, :participant_count, :participant_user_ids])
      )

    %Declaration{crew_id: crew_id}
    |> Ecto.Changeset.cast(insert_attrs, [
      :participant_count,
      :participant_user_ids,
      :unit_price,
      :total_amount,
      :status,
      :validated_at,
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
