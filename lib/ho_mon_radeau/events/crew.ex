defmodule HoMonRadeau.Events.Crew do
  @moduledoc """
  Schema for crews.
  A crew is the group of people who build and sail a raft together,
  or a transverse team that provides cross-cutting services.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.{Edition, Raft, CrewMember}

  @transverse_types ~w(welcome_team safe_team drums_team security medical other)

  schema "crews" do
    belongs_to :raft, Raft
    belongs_to :edition, Edition

    field :is_transverse, :boolean, default: false
    field :transverse_type, :string
    field :name, :string
    field :description, :string

    has_many :crew_members, CrewMember
    has_many :members, through: [:crew_members, :user]

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the list of valid transverse team types.
  """
  def transverse_types, do: @transverse_types

  @doc """
  Changeset for creating a crew (raft-based).
  """
  def changeset(crew, attrs) do
    crew
    |> cast(attrs, [:raft_id, :edition_id])
    |> validate_required([:raft_id, :edition_id])
    |> unique_constraint(:raft_id)
    |> foreign_key_constraint(:raft_id)
    |> foreign_key_constraint(:edition_id)
  end

  @doc """
  Changeset for creating a transverse team.
  """
  def transverse_changeset(crew, attrs) do
    crew
    |> cast(attrs, [:name, :description, :transverse_type, :is_transverse])
    |> put_change(:is_transverse, true)
    |> validate_required([:name, :transverse_type])
    |> validate_inclusion(:transverse_type, @transverse_types)
    |> validate_length(:name, min: 2, max: 100)
  end
end
