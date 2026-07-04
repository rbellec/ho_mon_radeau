defmodule HoMonRadeau.CUF.Exchange do
  @moduledoc """
  Schema for a crew's CUF exchange listing - a request for or an offer of
  CUFs, posted on the "À vot'bon Cuf" board for other crews to see.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Crew

  @kinds ~w(request offer)
  @statuses ~w(open fulfilled cancelled)

  schema "cuf_exchanges" do
    field :kind, :string
    field :quantity, :integer, default: 1
    field :status, :string, default: "open"
    field :note, :string

    belongs_to :crew, Crew

    timestamps(type: :utc_datetime)
  end

  def kinds, do: @kinds
  def statuses, do: @statuses

  @doc """
  Changeset for posting or updating a crew's open listing.
  """
  def changeset(exchange, attrs) do
    exchange
    |> cast(attrs, [:crew_id, :kind, :quantity, :note])
    |> validate_required([:crew_id, :kind, :quantity])
    |> validate_inclusion(:kind, @kinds)
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:crew_id)
    |> unique_constraint(:crew_id, name: :cuf_exchanges_open_unique)
  end

  @doc """
  Changeset for closing a listing (fulfilled or cancelled).
  """
  def close_changeset(exchange, status) when status in ["fulfilled", "cancelled"] do
    change(exchange, status: status)
  end
end
