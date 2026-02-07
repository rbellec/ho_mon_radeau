defmodule HoMonRadeau.Events.Raft do
  @moduledoc """
  Schema for rafts.
  A raft is the physical object that an crew builds and sails.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.{Edition, Crew, RaftLink}
  alias HoMonRadeau.Accounts.User

  schema "rafts" do
    field :name, :string
    field :description, :string
    field :description_short, :string
    field :forum_url, :string
    field :picture_url, :string
    field :slug, :string

    # Validation status
    field :validated, :boolean, default: false
    field :validated_at, :utc_datetime

    # Relationships
    belongs_to :edition, Edition
    belongs_to :validated_by, User
    belongs_to :previous_raft, __MODULE__

    has_one :crew, Crew
    has_many :links, RaftLink

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a raft.
  """
  def changeset(raft, attrs) do
    raft
    |> cast(attrs, [
      :name,
      :description,
      :description_short,
      :forum_url,
      :picture_url,
      :edition_id
    ])
    |> validate_required([:name, :edition_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description_short, max: 150)
    |> validate_url(:forum_url)
    |> generate_slug()
    |> unique_constraint([:name, :edition_id])
    |> unique_constraint([:slug, :edition_id])
  end

  @doc """
  Changeset for admin validation.
  """
  def validation_changeset(raft, attrs) do
    raft
    |> cast(attrs, [:validated, :validated_at, :validated_by_id])
  end

  @doc """
  Changeset for updating raft info (by managers).
  """
  def update_changeset(raft, attrs) do
    raft
    |> cast(attrs, [:description, :description_short, :forum_url, :picture_url])
    |> validate_length(:description_short, max: 150)
    |> validate_url(:forum_url)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and is_binary(host) ->
          []

        _ ->
          [{field, "must be a valid URL"}]
      end
    end)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        slug =
          name
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/\s+/, "-")
          |> String.trim("-")

        put_change(changeset, :slug, slug)
    end
  end
end
