defmodule HoMonRadeau.Events.RaftLink do
  @moduledoc """
  Schema for raft links.
  External links/documents associated with a raft.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Raft

  schema "raft_links" do
    field :title, :string
    field :url, :string
    field :position, :integer, default: 0

    belongs_to :raft, Raft

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating a raft link.
  """
  def changeset(raft_link, attrs) do
    raft_link
    |> cast(attrs, [:raft_id, :title, :url, :position])
    |> validate_required([:raft_id, :title, :url])
    |> validate_length(:title, max: 200)
    |> validate_url(:url)
    |> foreign_key_constraint(:raft_id)
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
end
