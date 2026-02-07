defmodule HoMonRadeau.Events.Crew do
  @moduledoc """
  Schema for crews.
  A crew is the group of people who build and sail a raft together.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.{Edition, Raft, CrewMember}

  schema "crews" do
    belongs_to :raft, Raft
    belongs_to :edition, Edition

    has_many :crew_members, CrewMember
    has_many :members, through: [:crew_members, :user]

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a crew.
  """
  def changeset(crew, attrs) do
    crew
    |> cast(attrs, [:raft_id, :edition_id])
    |> validate_required([:raft_id, :edition_id])
    |> unique_constraint(:raft_id)
    |> foreign_key_constraint(:raft_id)
    |> foreign_key_constraint(:edition_id)
  end
end
